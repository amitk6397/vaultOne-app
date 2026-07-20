import { useEffect, useState } from 'react'
import { adminApi } from '../services/api'
import { ErrorMessage, SuccessMessage } from '../components/Feedback'
import { TextArea, TextInput } from '../components/FormControls'

const emptyPage = { title: '', subtitle: '', sections: [] }

export function SupportManager() {
  const [pageKey, setPageKey] = useState('help')
  const [page, setPage] = useState(emptyPage)
  const [threads, setThreads] = useState([])
  const [selected, setSelected] = useState(null)
  const [messages, setMessages] = useState([])
  const [reply, setReply] = useState('')
  const [error, setError] = useState(''); const [success, setSuccess] = useState('')

  const load = async () => {
    try { const [content, list] = await Promise.all([adminApi.supportContent(pageKey), adminApi.supportThreads()]); setPage(content.data || emptyPage); setThreads(list.data || []) }
    catch (err) { setError(err.message) }
  }
  useEffect(() => {
    // Loading remote content in response to the selected page is intentional.
    // eslint-disable-next-line react-hooks/set-state-in-effect
    load()
  }, [pageKey]) // eslint-disable-line react-hooks/exhaustive-deps
  const openThread = async (thread) => { setSelected(thread); const response = await adminApi.supportMessages(thread.id); setMessages(response.data || []); await load() }
  const save = async () => { setError(''); try { await adminApi.saveSupportContent(pageKey, page); setSuccess(`${pageKey === 'help' ? 'Help' : 'About'} content saved.`) } catch (err) { setError(err.message) } }
  const sendReply = async () => { if (!reply.trim() || !selected) return; await adminApi.replySupport(selected.id, reply.trim()); setReply(''); await openThread(selected) }
  const updateSection = (index, key, value) => setPage((current) => ({ ...current, sections: current.sections.map((section, i) => i === index ? { ...section, [key]: value } : section) }))

  return <div className="space-y-6">
    <ErrorMessage message={error}/><SuccessMessage message={success}/>
    <section className="rounded-xl border bg-white p-5 shadow-sm">
      <div className="mb-5 flex gap-2">{['help','about'].map((key) => <button key={key} onClick={() => setPageKey(key)} className={`rounded-lg px-4 py-2 font-bold ${pageKey===key?'bg-blue-700 text-white':'bg-slate-100'}`}>{key === 'help' ? 'Help content' : 'About us'}</button>)}</div>
      <div className="grid gap-4"><TextInput label="Page title" value={page.title || ''} onChange={(value) => setPage({...page,title:value})}/><TextArea label="Subtitle" value={page.subtitle || ''} onChange={(value) => setPage({...page,subtitle:value})}/>
        {(page.sections || []).map((section,index) => <div key={index} className="grid gap-3 rounded-lg border p-4"><TextInput label={`Section ${index+1} title`} value={section.title || ''} onChange={(value)=>updateSection(index,'title',value)}/><TextArea label="Content" value={section.body || ''} onChange={(value)=>updateSection(index,'body',value)}/><button className="text-left text-sm font-bold text-red-600" onClick={()=>setPage({...page,sections:page.sections.filter((_,i)=>i!==index)})}>Remove section</button></div>)}
        <div className="flex gap-3"><button className="rounded-lg border px-4 py-2 font-bold" onClick={()=>setPage({...page,sections:[...(page.sections||[]),{title:'',body:''}]})}>Add section</button><button className="rounded-lg bg-blue-700 px-5 py-2 font-bold text-white" onClick={save}>Save content</button></div>
      </div>
    </section>
    <section className="grid gap-4 lg:grid-cols-[320px_1fr]">
      <div className="rounded-xl border bg-white p-3"> <h2 className="p-2 text-lg font-black">User conversations</h2>{threads.map((thread)=><button key={thread.id} onClick={()=>openThread(thread)} className={`mb-2 w-full rounded-lg p-3 text-left ${selected?.id===thread.id?'bg-blue-50 ring-1 ring-blue-500':'bg-slate-50'}`}><p className="font-black">{thread.user_name}{thread.has_unread && <span className="ml-2 text-blue-700">●</span>}</p><p className="text-xs text-slate-500">{thread.user_email}</p></button>)}</div>
      <div className="rounded-xl border bg-white p-4"><h2 className="mb-4 text-lg font-black">{selected ? `Chat with ${selected.user_name}` : 'Select a conversation'}</h2><div className="max-h-[420px] space-y-3 overflow-y-auto">{messages.map((item)=><div key={item.id} className={`max-w-[80%] rounded-xl px-4 py-3 ${item.sender_type==='admin'?'ml-auto bg-blue-700 text-white':'bg-slate-100'}`}><p>{item.message}</p></div>)}</div>{selected && <div className="mt-4 flex gap-2"><input value={reply} onChange={(e)=>setReply(e.target.value)} onKeyDown={(e)=>e.key==='Enter'&&sendReply()} className="flex-1 rounded-lg border px-4 py-3" placeholder="Type a reply..."/><button onClick={sendReply} className="rounded-lg bg-blue-700 px-5 font-bold text-white">Reply</button></div>}</div>
    </section>
  </div>
}
