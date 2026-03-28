import { useState, useEffect, useCallback } from "react";
import { db } from "./firebase";
import { doc, setDoc, onSnapshot } from "firebase/firestore";

(() => {
  const link = document.createElement("link");
  link.rel = "stylesheet";
  link.href = "https://fonts.googleapis.com/css2?family=Sora:wght@400;600;700&family=Noto+Sans+JP:wght@400;500;700&display=swap";
  document.head.appendChild(link);
  const meta = document.querySelector("meta[name=viewport]");
  if (meta) meta.content = "width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no";
  else {
    const m = document.createElement("meta");
    m.name = "viewport";
    m.content = "width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no";
    document.head.appendChild(m);
  }
  document.addEventListener("gesturestart", (e) => e.preventDefault(), { passive: false });
  document.addEventListener("touchmove", (e) => { if (e.touches.length > 1) e.preventDefault(); }, { passive: false });
})();

const DOC_REF = doc(db, "warikan", "shared");

const CA      = "#FF5133";
const CB      = "#2563EB";
const CBORROW = "#F97316";
const CREPAY  = "#22C55E";
const BG      = "#F5F3EE";

const fmt     = (n) => `¥${Math.abs(Math.round(n)).toLocaleString("ja-JP")}`;
const fmtDate = (iso) => { const d = new Date(iso); return `${d.getMonth()+1}/${d.getDate()}`; };
const genId   = () => Date.now().toString(36) + Math.random().toString(36).slice(2,6);

// ── EntryRow (履歴タブ用フラットリスト) ──
function EntryRow({ entry, names, onDelete, isCompleted }) {
  if (entry.type === "reset") {
    const isDebtReset = entry.snapshot?.debt !== undefined;
    return (
      <div style={{ background:"#FFF8F0", border:"1px solid #FFE0C8", borderRadius:12,
        padding:"10px 14px", marginBottom:8, display:"flex", alignItems:"center", gap:10 }}>
        <div style={{ width:28, height:28, borderRadius:8, background:"#FF9A6C",
          display:"flex", alignItems:"center", justifyContent:"center", fontSize:13, flexShrink:0 }}>🔄</div>
        <div style={{ flex:1, minWidth:0 }}>
          <div style={{ fontSize:13, fontWeight:700, color:"#C05000" }}>リセット</div>
          <div style={{ fontSize:11, color:"#C08060", marginTop:1, lineHeight:1.5 }}>
            {fmtDate(entry.date)} · {isDebtReset
              ? `残り ${fmt(entry.snapshot.debt)}`
              : `${names.A} ${fmt(entry.snapshot?.totA??0)} / ${names.B} ${fmt(entry.snapshot?.totB??0)}`}
          </div>
        </div>
        <button onClick={() => onDelete(entry)} style={{ background:"none", border:"none",
          color:"#e0c0a0", fontSize:15, cursor:"pointer", padding:"4px 6px", flexShrink:0, lineHeight:1 }}>✕</button>
      </div>
    );
  }
  if (entry.type === "borrow") {
    return (
      <div style={{ background:"#fff", borderRadius:12, padding:"12px 14px",
        marginBottom:8, display:"flex", alignItems:"center", gap:10,
        boxShadow:"0 1px 6px rgba(0,0,0,0.05)" }}>
        <div style={{ width:28, height:28, borderRadius:8, background:isCompleted?"#AAA":CBORROW,
          display:"flex", alignItems:"center", justifyContent:"center", fontSize:14, flexShrink:0 }}>💸</div>
        <div style={{ flex:1, minWidth:0 }}>
          <div style={{ display:"flex", alignItems:"center", gap:6 }}>
            <div style={{ fontSize:15, fontWeight:700, color:"#1A1A1A", letterSpacing:"-0.3px" }}>{fmt(entry.amount)}</div>
            {isCompleted && <div style={{ fontSize:10, fontWeight:700, color:"#22C55E", background:"#22C55E18",
              padding:"1px 6px", borderRadius:10 }}>完済</div>}
          </div>
          <div style={{ fontSize:11, color:"#999", marginTop:1 }}>
            {fmtDate(entry.date)} · {names[entry.borrower]||entry.borrower}が借りる{entry.memo ? ` · ${entry.memo}` : ""}
          </div>
        </div>
        <button onClick={() => onDelete(entry)} style={{ background:"none", border:"none",
          color:"#ccc", fontSize:15, cursor:"pointer", padding:"4px 6px", flexShrink:0, lineHeight:1 }}>✕</button>
      </div>
    );
  }
  if (entry.type === "repayment" || entry.type === "repay") {
    return (
      <div style={{ background:"#fff", borderRadius:12, padding:"12px 14px",
        marginBottom:8, display:"flex", alignItems:"center", gap:10,
        boxShadow:"0 1px 6px rgba(0,0,0,0.05)" }}>
        <div style={{ width:28, height:28, borderRadius:8, background:CREPAY,
          display:"flex", alignItems:"center", justifyContent:"center", fontSize:14, flexShrink:0 }}>✅</div>
        <div style={{ flex:1, minWidth:0 }}>
          <div style={{ fontSize:15, fontWeight:700, color:"#1A1A1A", letterSpacing:"-0.3px" }}>{fmt(entry.amount)}</div>
          <div style={{ fontSize:11, color:"#999", marginTop:1 }}>
            {fmtDate(entry.date)} · 返済{entry.memo ? ` · ${entry.memo}` : ""}
          </div>
        </div>
        <button onClick={() => onDelete(entry)} style={{ background:"none", border:"none",
          color:"#ccc", fontSize:15, cursor:"pointer", padding:"4px 6px", flexShrink:0, lineHeight:1 }}>✕</button>
      </div>
    );
  }
  // payment
  const c = entry.user === "A" ? CA : CB;
  return (
    <div style={{ background:"#fff", borderRadius:12, padding:"12px 14px",
      marginBottom:8, display:"flex", alignItems:"center", gap:10,
      boxShadow:"0 1px 6px rgba(0,0,0,0.05)" }}>
      <div style={{ width:28, height:28, borderRadius:8, background:c,
        display:"flex", alignItems:"center", justifyContent:"center",
        fontSize:11, fontWeight:700, color:"#fff", flexShrink:0, fontFamily:"'Sora',sans-serif" }}>
        {(names[entry.user]||entry.user)[0]?.toUpperCase()}
      </div>
      <div style={{ flex:1, minWidth:0 }}>
        <div style={{ fontSize:15, fontWeight:700, color:"#1A1A1A", letterSpacing:"-0.3px" }}>{fmt(entry.amount)}</div>
        <div style={{ fontSize:11, color:"#999", marginTop:1 }}>
          {fmtDate(entry.date)} · {names[entry.user]||entry.user}{entry.memo ? ` · ${entry.memo}` : ""}
        </div>
      </div>
      <button onClick={() => onDelete(entry)} style={{ background:"none", border:"none",
        color:"#ccc", fontSize:15, cursor:"pointer", padding:"4px 6px", flexShrink:0, lineHeight:1 }}>✕</button>
    </div>
  );
}

// ── BorrowCard (借りモードのアクティブ借り) ──
function BorrowCard({ borrow, names, onRepay, onDelete }) {
  const pct = Math.min(100, Math.round((borrow.repaid / borrow.amount) * 100));
  return (
    <div style={{ background:"#fff", borderRadius:16, padding:"16px", marginBottom:10,
      boxShadow:"0 2px 12px rgba(0,0,0,0.07)" }}>
      <div style={{ display:"flex", alignItems:"flex-start", justifyContent:"space-between", marginBottom:10 }}>
        <div style={{ flex:1, minWidth:0 }}>
          <div style={{ display:"flex", alignItems:"center", gap:8, marginBottom:4 }}>
            <div style={{ width:26, height:26, borderRadius:7, background:CBORROW,
              display:"flex", alignItems:"center", justifyContent:"center",
              fontSize:12, fontWeight:700, color:"#fff", flexShrink:0, fontFamily:"'Sora',sans-serif" }}>
              {(names[borrow.borrower]||borrow.borrower)[0]?.toUpperCase()}
            </div>
            <div style={{ fontSize:14, fontWeight:700, color:"#1A1A1A" }}>
              {names[borrow.borrower]} が借りる
            </div>
          </div>
          {borrow.memo && <div style={{ fontSize:11, color:"#AAA", paddingLeft:34 }}>{borrow.memo}</div>}
        </div>
        <button onClick={() => onDelete(borrow)} style={{ background:"none", border:"none",
          color:"#DDD", fontSize:15, cursor:"pointer", padding:"2px 4px", flexShrink:0, lineHeight:1 }}>✕</button>
      </div>

      <div style={{ display:"flex", justifyContent:"space-between", marginBottom:6 }}>
        <div>
          <div style={{ fontSize:11, color:"#AAA", marginBottom:2 }}>残り</div>
          <div style={{ fontSize:24, fontWeight:700, color:CBORROW, fontFamily:"'Sora',sans-serif",
            letterSpacing:"-0.5px" }}>{fmt(borrow.remaining)}</div>
        </div>
        <div style={{ textAlign:"right" }}>
          <div style={{ fontSize:11, color:"#AAA", marginBottom:2 }}>元金 / 返済済み</div>
          <div style={{ fontSize:13, color:"#888", fontFamily:"'Sora',sans-serif" }}>
            {fmt(borrow.amount)} / {fmt(borrow.repaid)}
          </div>
        </div>
      </div>

      {borrow.repaid > 0 && (
        <div style={{ background:"#F5F3EE", borderRadius:8, height:6, marginBottom:10, overflow:"hidden" }}>
          <div style={{ background:CREPAY, height:"100%", width:`${pct}%`, borderRadius:8, transition:"width 0.3s" }}/>
        </div>
      )}

      <button onClick={() => onRepay(borrow)} style={{ width:"100%", padding:"11px",
        background:CREPAY, color:"#fff", border:"none", borderRadius:12,
        fontSize:14, fontWeight:700, cursor:"pointer", fontFamily:"'Noto Sans JP',sans-serif",
        boxShadow:`0 3px 12px ${CREPAY}40` }}>
        ✅ 返した
      </button>
    </div>
  );
}

export default function App() {
  const [books,   setBooks]   = useState([{ id:"b1", name:"日常費", mode:"split" }]);
  const [entries, setEntries] = useState([]);
  const [names,   setNames]   = useState({ A:"A", B:"B" });
  const [bookId,  setBookId]  = useState("b1");
  const [tab,     setTab]     = useState("home");
  const [loading, setLoading] = useState(true);
  const [lastSync,setLastSync]= useState(null);

  // sheet: null | {type:"payment",user} | {type:"borrow"} | {type:"repay",borrow,remaining}
  const [sheet,      setSheet]      = useState(null);
  const [borrower,   setBorrower]   = useState("A");
  const [amount,     setAmount]     = useState("");
  const [memo,       setMemo]       = useState("");
  const [submitting, setSubmitting] = useState(false);

  const [newBookName, setNewBookName] = useState("");
  const [newBookMode, setNewBookMode] = useState("split");
  const [editNames,   setEditNames]   = useState(null);
  const [showReset,     setShowReset]     = useState(false);
  const [confirmDelete, setConfirmDelete] = useState(null);

  const loadData = useCallback(() => setLastSync(new Date()), []);

  useEffect(() => {
    const unsub = onSnapshot(DOC_REF, (snap) => {
      if (snap.exists()) {
        const data = snap.data();
        if (data.books) {
          const bs = data.books;
          setBooks(bs);
          setBookId((prev) => bs.find((b) => b.id === prev) ? prev : bs[0]?.id || "b1");
        }
        if (data.entries) setEntries(data.entries);
        if (data.names)   setNames(data.names);
      }
      setLastSync(new Date());
      setLoading(false);
    }, () => setLoading(false));
    return unsub;
  }, []);

  const saveBooks   = async (bs) => { setBooks(bs);   try { await setDoc(DOC_REF, { books:   bs }, { merge: true }); } catch {} };
  const saveEntries = async (es) => { setEntries(es); try { await setDoc(DOC_REF, { entries: es }, { merge: true }); } catch {} };
  const saveNames   = async (ns) => { setNames(ns);   try { await setDoc(DOC_REF, { names:   ns }, { merge: true }); } catch {} };

  const allCur    = entries.filter((e)=>e.bookId===bookId).sort((a,b)=>new Date(b.date)-new Date(a.date));
  const chronoCur = [...allCur].reverse();
  const lastResetPos  = chronoCur.findLastIndex((e)=>e.type==="reset");
  const activeEntries = lastResetPos===-1 ? allCur : allCur.slice(0, allCur.length - lastResetPos - 1);

  // 差額モード計算
  const totA = activeEntries.filter((e)=>e.user==="A"&&e.type!=="reset").reduce((s,e)=>s+e.amount,0);
  const totB = activeEntries.filter((e)=>e.user==="B"&&e.type!=="reset").reduce((s,e)=>s+e.amount,0);
  const diff = totA - totB;

  // 借りモード計算
  const isRepayType = (e) => e.type==="repayment" || e.type==="repay"; // 旧スキーマ互換
  const calcRemaining = (b, pool) => {
    const repaid = pool.filter((e)=>isRepayType(e)&&e.borrowId===b.id).reduce((s,e)=>s+e.amount,0);
    return { ...b, repaid, remaining: b.amount - repaid };
  };
  const borrowsInPeriod    = activeEntries.filter((e)=>e.type==="borrow").map((b)=>calcRemaining(b, activeEntries));
  const activeBorrows      = borrowsInPeriod.filter((b)=>b.remaining>0);
  // completedBorrowIds は allCur 全体で判定（履歴タブでリセット前の完済も正しく表示するため）
  const completedBorrowIds = new Set(
    allCur.filter((e)=>e.type==="borrow")
      .map((b)=>calcRemaining(b, allCur))
      .filter((b)=>b.remaining<=0)
      .map((b)=>b.id)
  );

  const curMode = books.find((b)=>b.id===bookId)?.mode || "split";
  const uColor  = (u) => u==="A" ? CA : CB;

  // Drawer の色・ラベル
  const sheetColor = sheet?.type==="repay" ? CREPAY : sheet?.type==="borrow" ? CBORROW
    : (sheet?.user ? uColor(sheet.user) : "#ccc");
  const sheetTitle = sheet?.type==="repay"
    ? "返済を記録"
    : sheet?.type==="borrow"
    ? "借りる記録"
    : sheet?.user ? `${names[sheet.user]} の支払いを記録` : "";

  const closeSheet = () => { setSheet(null); setAmount(""); setMemo(""); setBorrower("A"); };

  const openRepay = (borrow) => {
    setSheet({ type:"repay", borrow });
    setAmount(String(borrow.remaining));
    setMemo("");
  };

  const handleSubmit = async () => {
    const n = parseInt(amount.replace(/[^0-9]/g,""),10);
    if (!n||isNaN(n)||n<=0) return;
    setSubmitting(true);
    try {
      let entry;
      if (sheet.type==="payment") {
        entry = { id:genId(), bookId, type:"payment", user:sheet.user, amount:n, memo:memo.trim(), date:new Date().toISOString() };
      } else if (sheet.type==="borrow") {
        entry = { id:genId(), bookId, type:"borrow", borrower, amount:n, memo:memo.trim(), date:new Date().toISOString() };
      } else if (sheet.type==="repay") {
        entry = { id:genId(), bookId, type:"repayment", borrowId:sheet.borrow.id, amount:n, memo:memo.trim(), date:new Date().toISOString() };
      }
      await saveEntries([entry,...entries]);
      closeSheet();
    } finally { setSubmitting(false); }
  };

  const handleReset = async () => {
    const snapshot = curMode==="debt" ? { activeBorrows: activeBorrows.length } : { totA, totB };
    await saveEntries([{id:genId(),bookId,type:"reset",snapshot,date:new Date().toISOString()},...entries]);
    setShowReset(false);
  };

  const handleDelete      = async (id) => saveEntries(entries.filter((e)=>e.id!==id));
  const requestDelete     = (entry) => setConfirmDelete(entry);
  const confirmDeleteEntry = async () => {
    if (!confirmDelete) return;
    await handleDelete(confirmDelete.id);
    setConfirmDelete(null);
  };

  const handleAddBook = async () => {
    if (!newBookName.trim()) return;
    await saveBooks([...books,{id:genId(),name:newBookName.trim(),mode:newBookMode}]);
    setNewBookName(""); setNewBookMode("split");
  };

  const handleDeleteBook = async (id) => {
    if (books.length<=1) return;
    const nb = books.filter((b)=>b.id!==id);
    await saveBooks(nb);
    await saveEntries(entries.filter((e)=>e.bookId!==id));
    if (bookId===id) setBookId(nb[0].id);
  };

  const handleSaveNames = async () => {
    if (!editNames) return;
    await saveNames({ A:editNames.A.trim()||"A", B:editNames.B.trim()||"B" });
    setEditNames(null);
  };

  const font    = "'Noto Sans JP','Sora',sans-serif";
  const numFont = "'Sora','Noto Sans JP',sans-serif";

  if (loading) return (
    <div style={{ display:"flex",height:"100vh",alignItems:"center",justifyContent:"center",background:BG,fontFamily:font,color:"#aaa",fontSize:14 }}>読み込み中…</div>
  );

  return (
    <div style={{ fontFamily:font,background:BG,minHeight:"100vh",maxWidth:430,margin:"0 auto",
      position:"relative",paddingBottom:80,WebkitTextSizeAdjust:"100%",touchAction:"pan-y" }}>

      {/* Header */}
      <div style={{ background:"#fff",padding:"16px 20px 0",borderBottom:"1px solid #EDE9E2",
        position:"sticky",top:0,zIndex:50 }}>
        <div style={{ display:"flex",alignItems:"center",justifyContent:"space-between",marginBottom:12 }}>
          <div style={{ fontSize:18,fontWeight:700,color:"#1A1A1A",letterSpacing:"-0.5px",fontFamily:numFont }}>かんたん家計簿</div>
          <button onClick={loadData} style={{ background:"#F5F3EE",border:"none",borderRadius:8,
            padding:"5px 10px",fontSize:11,color:"#888",cursor:"pointer",fontFamily:font }}>
            ↻ {lastSync?`${String(lastSync.getHours()).padStart(2,"0")}:${String(lastSync.getMinutes()).padStart(2,"0")}`:"更新"}
          </button>
        </div>
        <div style={{ display:"flex",gap:4,overflowX:"auto",scrollbarWidth:"none" }}>
          {books.map((b)=>(
            <button key={b.id} onClick={()=>setBookId(b.id)} style={{ padding:"7px 14px",borderRadius:"8px 8px 0 0",border:"none",
              background:bookId===b.id?BG:"transparent",color:bookId===b.id?"#1A1A1A":"#AAA",
              fontWeight:bookId===b.id?700:400,fontSize:13,cursor:"pointer",whiteSpace:"nowrap",
              fontFamily:font,transition:"all 0.15s" }}>{b.name}</button>
          ))}
        </div>
      </div>

      {/* Home */}
      {tab==="home" && (
        <div style={{ padding:"20px 16px" }}>

          {/* ── 差額モード ── */}
          {curMode==="split" && (<>
            <div style={{ background:"#fff",borderRadius:22,padding:"28px 24px 22px",
              marginBottom:14,boxShadow:"0 2px 20px rgba(0,0,0,0.06)",textAlign:"center" }}>
              {diff===0 ? (
                <>
                  <div style={{ fontSize:12,color:"#AAA",marginBottom:10,letterSpacing:"0.5px",fontWeight:500 }}>現在の差額</div>
                  <div style={{ fontSize:38,fontWeight:700,color:"#22C55E",fontFamily:numFont,letterSpacing:"-1px" }}>フラット！ 🎉</div>
                  <div style={{ fontSize:12,color:"#bbb",marginTop:8 }}>ふたりとも同じ金額です</div>
                </>
              ) : (
                <>
                  <div style={{ fontSize:12,color:"#AAA",marginBottom:10,letterSpacing:"0.5px",fontWeight:500 }}>現在の差額</div>
                  <div style={{ display:"inline-block",padding:"3px 12px",borderRadius:20,
                    background:diff>0?`${CA}18`:`${CB}18`,color:diff>0?CA:CB,
                    fontSize:11,fontWeight:700,letterSpacing:"0.5px",marginBottom:10 }}>
                    {diff>0?names.A:names.B} の方が多く持っています
                  </div>
                  <div style={{ fontSize:50,fontWeight:700,fontFamily:numFont,
                    color:diff>0?CA:CB,letterSpacing:"-2px",lineHeight:1 }}>{fmt(diff)}</div>
                  <div style={{ fontSize:12,color:"#bbb",marginTop:14,lineHeight:1.8 }}>
                    {diff>0?names.B:names.A} → {diff>0?names.A:names.B} に
                    <span style={{ fontWeight:700,color:"#666" }}> {fmt(Math.abs(diff)/2)} </span>
                    渡すとフラットになります
                  </div>
                </>
              )}
              <button onClick={()=>setShowReset(true)} style={{ marginTop:18,background:"none",
                border:"1.5px solid #E0DDD8",borderRadius:10,padding:"7px 20px",
                fontSize:12,color:"#AAA",cursor:"pointer",fontFamily:font,fontWeight:600 }}>
                🔄 リセット
              </button>
            </div>

            <div style={{ fontSize:11,color:"#AAA",marginBottom:8,fontWeight:600,paddingLeft:4,letterSpacing:"0.5px" }}>支払いを追加</div>
            <div style={{ display:"grid",gridTemplateColumns:"1fr 1fr",gap:10,marginBottom:24 }}>
              {["A","B"].map((u)=>(
                <button key={u} onClick={()=>setSheet({type:"payment",user:u})}
                  style={{ background:uColor(u),color:"#fff",border:"none",borderRadius:16,padding:"18px 16px",
                    fontSize:16,fontWeight:700,cursor:"pointer",fontFamily:numFont,boxShadow:`0 4px 18px ${uColor(u)}45`,
                    display:"flex",alignItems:"center",justifyContent:"center",gap:8,transition:"transform 0.1s" }}
                  onMouseDown={(e)=>(e.currentTarget.style.transform="scale(0.96)")}
                  onMouseUp={(e)=>(e.currentTarget.style.transform="scale(1)")}
                  onTouchStart={(e)=>(e.currentTarget.style.transform="scale(0.96)")}
                  onTouchEnd={(e)=>(e.currentTarget.style.transform="scale(1)")}>
                  <span style={{ fontSize:22,lineHeight:1 }}>＋</span>{names[u]} 持ち
                </button>
              ))}
            </div>

            {allCur.length>0 ? (
              <>
                <div style={{ fontSize:11,color:"#AAA",marginBottom:8,fontWeight:600,paddingLeft:4,letterSpacing:"0.5px" }}>最近の履歴</div>
                {allCur.slice(0,4).map((e)=>(
                  <EntryRow key={e.id} entry={e} names={names} onDelete={requestDelete}
                    isCompleted={completedBorrowIds.has(e.id)}/>
                ))}
                {allCur.length>4&&(
                  <button onClick={()=>setTab("history")} style={{ width:"100%",padding:12,background:"none",
                    border:"1.5px dashed #DDD",borderRadius:12,color:"#888",
                    fontSize:13,cursor:"pointer",fontFamily:font,marginTop:4 }}>
                    全ての履歴を見る（{allCur.length} 件）
                  </button>
                )}
              </>
            ) : (
              <div style={{ background:"#fff",borderRadius:16,padding:"40px 24px",textAlign:"center",boxShadow:"0 1px 8px rgba(0,0,0,0.04)" }}>
                <div style={{ fontSize:36,marginBottom:12 }}>📝</div>
                <div style={{ fontSize:14,color:"#888" }}>まだ記録がありません</div>
                <div style={{ fontSize:12,color:"#bbb",marginTop:4 }}>上のボタンから追加してね</div>
              </div>
            )}
          </>)}

          {/* ── 借りモード ── */}
          {curMode==="debt" && (<>
            <div style={{ display:"flex",alignItems:"center",justifyContent:"space-between",marginBottom:12 }}>
              <div style={{ fontSize:11,color:"#AAA",fontWeight:600,letterSpacing:"0.5px" }}>
                返済中 {activeBorrows.length}件
              </div>
              <button onClick={()=>setSheet({type:"borrow"})}
                style={{ background:CBORROW,color:"#fff",border:"none",borderRadius:12,
                  padding:"9px 18px",fontSize:14,fontWeight:700,cursor:"pointer",fontFamily:font,
                  boxShadow:`0 3px 12px ${CBORROW}40`,display:"flex",alignItems:"center",gap:6 }}>
                <span style={{ fontSize:18,lineHeight:1 }}>💸</span> 借りる
              </button>
            </div>

            {activeBorrows.length===0 ? (
              <div style={{ background:"#fff",borderRadius:16,padding:"40px 24px",textAlign:"center",
                boxShadow:"0 1px 8px rgba(0,0,0,0.04)",marginBottom:16 }}>
                <div style={{ fontSize:36,marginBottom:12 }}>🎉</div>
                <div style={{ fontSize:16,fontWeight:700,color:"#22C55E" }}>借りなし！</div>
                <div style={{ fontSize:12,color:"#bbb",marginTop:4 }}>現在、借りている記録はありません</div>
              </div>
            ) : (
              activeBorrows.map((b)=>(
                <BorrowCard key={b.id} borrow={b} names={names} onRepay={openRepay} onDelete={requestDelete}/>
              ))
            )}
          </>)}

        </div>
      )}

      {/* History */}
      {tab==="history" && (
        <div style={{ padding:"16px" }}>
          {allCur.length===0
            ? <div style={{ textAlign:"center",color:"#bbb",padding:"80px 0",fontSize:14 }}>まだ記録がありません</div>
            : <>
                <div style={{ fontSize:11,color:"#AAA",marginBottom:10,fontWeight:600,paddingLeft:4,letterSpacing:"0.5px" }}>{allCur.length} 件の記録</div>
                {allCur.map((e)=>(
                  <EntryRow key={e.id} entry={e} names={names} onDelete={requestDelete}
                    isCompleted={completedBorrowIds.has(e.id)}/>
                ))}
              </>
          }
        </div>
      )}

      {/* Settings */}
      {tab==="books" && (
        <div style={{ padding:"16px" }}>
          <div style={{ fontSize:11,color:"#AAA",marginBottom:8,fontWeight:600,paddingLeft:4,letterSpacing:"0.5px" }}>ユーザー名</div>
          <div style={{ background:"#fff",borderRadius:16,padding:"18px 16px",marginBottom:16,boxShadow:"0 1px 6px rgba(0,0,0,0.05)" }}>
            {editNames ? (
              <>
                {["A","B"].map((u)=>(
                  <div key={u} style={{ display:"flex",alignItems:"center",gap:10,marginBottom:u==="A"?12:0 }}>
                    <div style={{ width:30,height:30,borderRadius:8,background:uColor(u),
                      display:"flex",alignItems:"center",justifyContent:"center",
                      fontSize:12,fontWeight:700,color:"#fff",flexShrink:0,fontFamily:numFont }}>{u}</div>
                    <input value={editNames[u]} onChange={(e)=>setEditNames((n)=>({...n,[u]:e.target.value}))}
                      maxLength={12} placeholder={u==="A"?"例: たろう":"例: はなこ"}
                      style={{ flex:1,minWidth:0,border:"1.5px solid #EDE9E2",borderRadius:10,
                        padding:"8px 10px",fontSize:16,fontFamily:font,outline:"none",background:BG,color:"#1A1A1A",boxSizing:"border-box" }}/>
                  </div>
                ))}
                <div style={{ display:"flex",gap:8,marginTop:14 }}>
                  <button onClick={()=>setEditNames(null)} style={{ flex:1,padding:"10px",background:"#F5F3EE",border:"none",
                    borderRadius:10,fontSize:14,cursor:"pointer",fontFamily:font,color:"#888" }}>キャンセル</button>
                  <button onClick={handleSaveNames} style={{ flex:1,padding:"10px",background:"#1A1A1A",border:"none",
                    borderRadius:10,fontSize:14,cursor:"pointer",fontFamily:font,color:"#fff",fontWeight:700 }}>保存</button>
                </div>
              </>
            ) : (
              <>
                {["A","B"].map((u)=>(
                  <div key={u} style={{ display:"flex",alignItems:"center",gap:10,marginBottom:u==="A"?10:0 }}>
                    <div style={{ width:30,height:30,borderRadius:8,background:uColor(u),
                      display:"flex",alignItems:"center",justifyContent:"center",
                      fontSize:12,fontWeight:700,color:"#fff",flexShrink:0,fontFamily:numFont }}>{u}</div>
                    <div style={{ fontSize:16,fontWeight:600,color:"#1A1A1A",flex:1 }}>{names[u]}</div>
                  </div>
                ))}
                <button onClick={()=>setEditNames({...names})} style={{ marginTop:14,width:"100%",padding:"10px",
                  background:"#F5F3EE",border:"none",borderRadius:10,fontSize:14,cursor:"pointer",
                  fontFamily:font,color:"#444",fontWeight:600 }}>✏️ 名前を編集</button>
              </>
            )}
          </div>

          <div style={{ fontSize:11,color:"#AAA",marginBottom:8,fontWeight:600,paddingLeft:4,letterSpacing:"0.5px" }}>ページ一覧</div>
          {books.map((b)=>(
            <div key={b.id} style={{ background:"#fff",borderRadius:12,padding:"14px 16px",marginBottom:8,
              display:"flex",alignItems:"center",justifyContent:"space-between",boxShadow:"0 1px 6px rgba(0,0,0,0.05)",
              borderLeft:bookId===b.id?"3px solid #1A1A1A":"3px solid transparent" }}>
              <div>
                <div style={{ display:"flex",alignItems:"center",gap:8 }}>
                  <div style={{ fontWeight:600,fontSize:15,color:"#1A1A1A" }}>{b.name}</div>
                  <div style={{ fontSize:10,fontWeight:700,padding:"2px 7px",borderRadius:20,
                    background:b.mode==="debt"?`${CBORROW}18`:"#E8F4FF",
                    color:b.mode==="debt"?CBORROW:CB }}>
                    {b.mode==="debt"?"借り":"差額"}
                  </div>
                </div>
                <div style={{ fontSize:11,color:"#AAA",marginTop:2 }}>{entries.filter((e)=>e.bookId===b.id).length} 件の記録</div>
              </div>
              <button onClick={()=>handleDeleteBook(b.id)} disabled={books.length<=1} style={{ background:"none",border:"none",
                color:books.length<=1?"#E0DDD8":"#FF5133",fontSize:17,cursor:books.length<=1?"default":"pointer",padding:8 }}>⌫</button>
            </div>
          ))}
          <div style={{ background:"#fff",borderRadius:16,padding:"18px 16px",marginTop:8,boxShadow:"0 1px 6px rgba(0,0,0,0.05)" }}>
            <div style={{ fontSize:11,color:"#AAA",marginBottom:10,fontWeight:600,letterSpacing:"0.5px" }}>新しいページを追加</div>
            <div style={{ display:"flex",gap:8,marginBottom:10 }}>
              {[["split","差額"],["debt","借り"]].map(([m,label])=>(
                <button key={m} onClick={()=>setNewBookMode(m)} style={{ flex:1,padding:"8px",border:"1.5px solid",
                  borderColor:newBookMode===m?(m==="debt"?CBORROW:CB):"#EDE9E2",
                  borderRadius:10,fontSize:13,fontWeight:700,cursor:"pointer",fontFamily:font,
                  background:newBookMode===m?(m==="debt"?`${CBORROW}12`:"#E8F4FF"):"#fff",
                  color:newBookMode===m?(m==="debt"?CBORROW:CB):"#AAA",transition:"all 0.15s" }}>{label}</button>
              ))}
            </div>
            <div style={{ display:"flex",gap:8 }}>
              <input value={newBookName} onChange={(e)=>setNewBookName(e.target.value)}
                onKeyDown={(e)=>e.key==="Enter"&&handleAddBook()} placeholder="例: 旅行費、外食..."
                style={{ flex:1,minWidth:0,border:"1.5px solid #EDE9E2",borderRadius:10,
                  padding:"8px 10px",fontSize:16,fontFamily:font,outline:"none",background:BG,color:"#1A1A1A",boxSizing:"border-box" }}/>
              <button onClick={handleAddBook} style={{ background:"#1A1A1A",color:"#fff",border:"none",flexShrink:0,
                borderRadius:10,padding:"8px 14px",fontSize:14,cursor:"pointer",fontFamily:font,fontWeight:700 }}>追加</button>
            </div>
          </div>
        </div>
      )}

      {/* Bottom Nav */}
      <div style={{ position:"fixed",bottom:0,left:"50%",transform:"translateX(-50%)",
        width:"100%",maxWidth:430,background:"#fff",borderTop:"1px solid #EDE9E2",
        display:"flex",paddingBottom:8,zIndex:50 }}>
        {[["home","🏠","ホーム"],["history","📋","履歴"],["books","⚙️","設定"]].map(([t,icon,label])=>(
          <button key={t} onClick={()=>setTab(t)} style={{ flex:1,background:"none",border:"none",
            padding:"10px 0 4px",cursor:"pointer",display:"flex",flexDirection:"column",alignItems:"center",gap:3 }}>
            <span style={{ fontSize:22,opacity:tab===t?1:0.35 }}>{icon}</span>
            <span style={{ fontSize:10,fontFamily:font,color:tab===t?"#1A1A1A":"#AAA",fontWeight:tab===t?700:400 }}>{label}</span>
          </button>
        ))}
      </div>

      {/* Add / Repay / Borrow Drawer */}
      {sheet && (
        <>
          <div onClick={closeSheet}
            style={{ position:"fixed",inset:0,background:"rgba(0,0,0,0.45)",zIndex:100 }}/>
          <div style={{ position:"fixed",bottom:0,left:"50%",transform:"translateX(-50%)",
            width:"100%",maxWidth:430,background:"#fff",borderRadius:"24px 24px 0 0",
            padding:"8px 24px 32px",zIndex:101,boxShadow:"0 -8px 40px rgba(0,0,0,0.15)",boxSizing:"border-box" }}>
            <div style={{ width:36,height:4,background:"#E0DDD8",borderRadius:2,margin:"12px auto 20px" }}/>
            <div style={{ fontSize:17,fontWeight:700,color:"#1A1A1A",marginBottom:16 }}>{sheetTitle}</div>

            {/* 借りる: 借りた人選択 */}
            {sheet.type==="borrow" && (
              <div style={{ marginBottom:16 }}>
                <div style={{ fontSize:11,color:"#AAA",marginBottom:8,fontWeight:600,letterSpacing:"0.5px" }}>借りた人</div>
                <div style={{ display:"flex",gap:8 }}>
                  {["A","B"].map((u)=>(
                    <button key={u} onClick={()=>setBorrower(u)} style={{ flex:1,padding:"10px",border:"2px solid",
                      borderColor:borrower===u?CBORROW:"#EDE9E2",
                      borderRadius:12,fontSize:14,fontWeight:700,cursor:"pointer",fontFamily:font,
                      background:borrower===u?`${CBORROW}12`:"#fff",
                      color:borrower===u?CBORROW:"#AAA",transition:"all 0.15s" }}>
                      {names[u]}
                    </button>
                  ))}
                </div>
              </div>
            )}

            {/* 返済: 対象の借り情報表示 */}
            {sheet.type==="repay" && (
              <div style={{ background:"#FFF8F2",border:`1px solid ${CBORROW}30`,borderRadius:12,
                padding:"10px 14px",marginBottom:16 }}>
                <div style={{ fontSize:11,color:CBORROW,fontWeight:700,marginBottom:2 }}>返済対象</div>
                <div style={{ fontSize:14,fontWeight:700,color:"#1A1A1A" }}>
                  {names[sheet.borrow.borrower]} · 残り {fmt(sheet.borrow.remaining)}
                </div>
                {sheet.borrow.memo && <div style={{ fontSize:11,color:"#AAA",marginTop:2 }}>{sheet.borrow.memo}</div>}
              </div>
            )}

            <div style={{ marginBottom:14 }}>
              <div style={{ fontSize:11,color:"#AAA",marginBottom:6,fontWeight:600,letterSpacing:"0.5px" }}>金額 *</div>
              <div style={{ position:"relative" }}>
                <span style={{ position:"absolute",left:14,top:"50%",transform:"translateY(-50%)",
                  fontSize:22,color:"#AAA",fontFamily:numFont,fontWeight:600 }}>¥</span>
                <input autoFocus inputMode="numeric" value={amount}
                  onChange={(e)=>setAmount(e.target.value.replace(/[^0-9]/g,""))}
                  onKeyDown={(e)=>e.key==="Enter"&&handleSubmit()} placeholder="0"
                  style={{ width:"100%",padding:"14px 14px 14px 38px",fontSize:32,fontWeight:700,
                    border:"2px solid",borderColor:sheetColor,borderRadius:14,
                    fontFamily:numFont,outline:"none",boxSizing:"border-box",color:"#1A1A1A",letterSpacing:"-0.5px" }}/>
              </div>
            </div>
            <div style={{ marginBottom:22 }}>
              <div style={{ fontSize:11,color:"#AAA",marginBottom:6,fontWeight:600,letterSpacing:"0.5px" }}>メモ（任意）</div>
              <input value={memo} onChange={(e)=>setMemo(e.target.value)}
                onKeyDown={(e)=>e.key==="Enter"&&handleSubmit()} placeholder="例: スーパー、ガソリン代..."
                style={{ width:"100%",padding:"12px 14px",fontSize:16,border:"1.5px solid #EDE9E2",
                  borderRadius:12,fontFamily:font,outline:"none",boxSizing:"border-box",background:BG,color:"#1A1A1A" }}/>
            </div>
            <button onClick={handleSubmit} disabled={!amount||submitting} style={{ width:"100%",padding:"17px",
              background:!amount?"#E0DDD8":sheetColor,color:"#fff",border:"none",borderRadius:16,
              fontSize:16,fontWeight:700,cursor:!amount?"default":"pointer",fontFamily:font,
              boxShadow:!amount?"none":`0 6px 20px ${sheetColor}50` }}>
              {submitting?"記録中…":"記録する ✓"}
            </button>
          </div>
        </>
      )}

      {/* Reset Drawer */}
      {showReset && (
        <>
          <div onClick={()=>setShowReset(false)}
            style={{ position:"fixed",inset:0,background:"rgba(0,0,0,0.45)",zIndex:100 }}/>
          <div style={{ position:"fixed",bottom:0,left:"50%",transform:"translateX(-50%)",
            width:"100%",maxWidth:430,background:"#fff",borderRadius:"24px 24px 0 0",
            padding:"8px 24px 32px",zIndex:101,boxShadow:"0 -8px 40px rgba(0,0,0,0.15)",boxSizing:"border-box" }}>
            <div style={{ width:36,height:4,background:"#E0DDD8",borderRadius:2,margin:"12px auto 24px" }}/>
            <div style={{ fontSize:18,fontWeight:700,color:"#1A1A1A",marginBottom:10 }}>🔄 リセット</div>
            <div style={{ fontSize:14,color:"#666",lineHeight:1.9,marginBottom:20 }}>
              現在の状況をリセットします。<br/>
              <span style={{ fontWeight:700,color:"#1A1A1A" }}>履歴は消えません。</span><br/>
              {curMode==="debt"
                ? `返済中 ${activeBorrows.length}件 の状況が履歴に残ります。`
                : `リセット時点の状況（${names.A} ${fmt(totA)} / ${names.B} ${fmt(totB)}）が履歴に残ります。`}
            </div>
            <div style={{ display:"flex",gap:10 }}>
              <button onClick={()=>setShowReset(false)} style={{ flex:1,padding:"14px",background:"#F5F3EE",
                border:"none",borderRadius:14,fontSize:15,cursor:"pointer",fontFamily:font,color:"#888",fontWeight:600 }}>キャンセル</button>
              <button onClick={handleReset} style={{ flex:1,padding:"14px",background:"#FF5133",border:"none",
                borderRadius:14,fontSize:15,cursor:"pointer",fontFamily:font,color:"#fff",fontWeight:700,
                boxShadow:"0 4px 16px #FF513350" }}>リセットする</button>
            </div>
          </div>
        </>
      )}

      {/* Confirm Delete Drawer */}
      {confirmDelete && (
        <>
          <div onClick={()=>setConfirmDelete(null)}
            style={{ position:"fixed",inset:0,background:"rgba(0,0,0,0.45)",zIndex:100 }}/>
          <div style={{ position:"fixed",bottom:0,left:"50%",transform:"translateX(-50%)",
            width:"100%",maxWidth:430,background:"#fff",borderRadius:"24px 24px 0 0",
            padding:"8px 24px 32px",zIndex:101,boxShadow:"0 -8px 40px rgba(0,0,0,0.15)",boxSizing:"border-box" }}>
            <div style={{ width:36,height:4,background:"#E0DDD8",borderRadius:2,margin:"12px auto 24px" }}/>
            <div style={{ fontSize:18,fontWeight:700,color:"#1A1A1A",marginBottom:10 }}>🗑️ 記録を削除</div>
            {confirmDelete.type==="reset" ? (
              <div style={{ background:"#FFF8F0",border:"1px solid #FFE0C8",borderRadius:12,padding:"12px 14px",marginBottom:20 }}>
                <div style={{ fontSize:13,fontWeight:700,color:"#C05000" }}>リセット履歴</div>
                <div style={{ fontSize:12,color:"#C08060",marginTop:4 }}>{fmtDate(confirmDelete.date)}</div>
              </div>
            ) : (
              <div style={{ background:"#F5F3EE",borderRadius:12,padding:"12px 14px",marginBottom:20 }}>
                <div style={{ fontSize:22,fontWeight:700,color:"#1A1A1A",letterSpacing:"-0.5px" }}>{fmt(confirmDelete.amount)}</div>
                <div style={{ fontSize:12,color:"#999",marginTop:4 }}>
                  {fmtDate(confirmDelete.date)} ·{" "}
                  {confirmDelete.type==="borrow" ? `${names[confirmDelete.borrower]||confirmDelete.borrower}が借りる`
                   : (confirmDelete.type==="repayment"||confirmDelete.type==="repay") ? "返済"
                   : names[confirmDelete.user]||confirmDelete.user}
                  {confirmDelete.memo ? ` · ${confirmDelete.memo}` : ""}
                </div>
              </div>
            )}
            <div style={{ fontSize:13,color:"#888",marginBottom:20 }}>この記録を削除しますか？この操作は取り消せません。</div>
            <div style={{ display:"flex",gap:10 }}>
              <button onClick={()=>setConfirmDelete(null)} style={{ flex:1,padding:"14px",background:"#F5F3EE",
                border:"none",borderRadius:14,fontSize:15,cursor:"pointer",fontFamily:font,color:"#888",fontWeight:600 }}>キャンセル</button>
              <button onClick={confirmDeleteEntry} style={{ flex:1,padding:"14px",background:"#FF5133",border:"none",
                borderRadius:14,fontSize:15,cursor:"pointer",fontFamily:font,color:"#fff",fontWeight:700,
                boxShadow:"0 4px 16px #FF513350" }}>削除する</button>
            </div>
          </div>
        </>
      )}
    </div>
  );
}
