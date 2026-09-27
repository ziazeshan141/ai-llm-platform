import React, { useState } from 'react';
import { createRoot } from 'react-dom/client';

import './style.css';


const API = import.meta.env.VITE_API_BASE_URL || '';


const navItems = [
  { name: 'Chat', icon: '✦' },
  { name: 'Documents', icon: '▤' },
  { name: 'Knowledge Base', icon: '◫' },
  { name: 'System', icon: '◉' },
];


function App() {
  const [page, setPage] = useState('Chat');

  const [msg, setMsg] = useState('');
  const [messages, setMessages] = useState([
    {
      role: 'assistant',
      content:
        "Hello! I'm your AI assistant. Ask me anything about DevOps, Kubernetes, cloud infrastructure, or your indexed knowledge base.",
    },
  ]);

  const [chatLoading, setChatLoading] = useState(false);

  const [title, setTitle] = useState('');
  const [content, setContent] = useState('');
  const [documentStatus, setDocumentStatus] = useState('');
  const [documentLoading, setDocumentLoading] = useState(false);

  const [query, setQuery] = useState('');
  const [results, setResults] = useState([]);
  const [searchLoading, setSearchLoading] = useState(false);


  // =========================================================
  // CHAT
  // =========================================================

  async function chat(e) {
    e.preventDefault();

    const message = msg.trim();

    if (!message || chatLoading) {
      return;
    }

    setMessages((current) => [
      ...current,
      {
        role: 'user',
        content: message,
      },
    ]);

    setMsg('');
    setChatLoading(true);

    try {
      const response = await fetch(
        `${API}/api/v1/ai/chat`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            message,
          }),
        },
      );

      const data = await response.json();

      setMessages((current) => [
        ...current,
        {
          role: 'assistant',
          content: response.ok
            ? data.answer
            : data.detail ||
              'AI service is currently unavailable.',
        },
      ]);
    } catch {
      setMessages((current) => [
        ...current,
        {
          role: 'assistant',
          content:
            'Unable to connect to the AI service.',
        },
      ]);
    } finally {
      setChatLoading(false);
    }
  }


  // =========================================================
  // ENTER TO SEND
  // SHIFT + ENTER FOR NEW LINE
  // =========================================================

  function handleChatKeyDown(e) {
    if (e.key !== 'Enter') {
      return;
    }

    if (e.shiftKey) {
      return;
    }

    e.preventDefault();

    if (!msg.trim() || chatLoading) {
      return;
    }

    e.currentTarget.form?.requestSubmit();
  }


  // =========================================================
  // ADD DOCUMENT
  // =========================================================

  async function addDocument(e) {
    e.preventDefault();

    if (
      !title.trim() ||
      !content.trim() ||
      documentLoading
    ) {
      return;
    }

    setDocumentLoading(true);
    setDocumentStatus('');

    try {
      const response = await fetch(
        `${API}/api/v1/rag/documents`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            title: title.trim(),
            content: content.trim(),
          }),
        },
      );

      const data = await response.json();

      if (response.ok) {
        setDocumentStatus(
          `Document indexed successfully. ${data.chunks_created} chunks created.`,
        );

        setTitle('');
        setContent('');
      } else {
        setDocumentStatus(
          data.detail ||
            'Unable to index document.',
        );
      }
    } catch {
      setDocumentStatus(
        'Unable to connect to the RAG service.',
      );
    } finally {
      setDocumentLoading(false);
    }
  }


  // =========================================================
  // SEMANTIC SEARCH
  // =========================================================

  async function search(e) {
    e.preventDefault();

    if (!query.trim() || searchLoading) {
      return;
    }

    setSearchLoading(true);

    try {
      const response = await fetch(
        `${API}/api/v1/rag/search`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            query: query.trim(),
          }),
        },
      );

      const data = await response.json();

      if (response.ok) {
        setResults(
          Array.isArray(data)
            ? data
            : [],
        );
      } else {
        setResults([]);
      }
    } catch {
      setResults([]);
    } finally {
      setSearchLoading(false);
    }
  }


  // =========================================================
  // CLEAR CHAT
  // =========================================================

  function clearChat() {
    setMessages([
      {
        role: 'assistant',
        content:
          'Conversation cleared. What would you like to explore?',
      },
    ]);
  }


  // =========================================================
  // UI
  // =========================================================

  return (
    <div className="app-shell">

      {/* SIDEBAR */}

      <aside className="sidebar">

        <div>

          <div className="brand">

            <div className="brand-logo">
              AI
            </div>

            <div>
              <h2>AI Platform</h2>
              <span>LLM + RAG Workspace</span>
            </div>

          </div>


          <nav>

            {navItems.map((item) => (

              <button
                key={item.name}
                type="button"
                className={`nav-item ${
                  page === item.name
                    ? 'active'
                    : ''
                }`}
                onClick={() =>
                  setPage(item.name)
                }
              >

                <span className="nav-icon">
                  {item.icon}
                </span>

                {item.name}

              </button>

            ))}

          </nav>

        </div>


        <div className="sidebar-footer">

          <div className="status-row">

            <span className="status-dot online" />

            Platform Online

          </div>

          <span>
            Minikube Environment
          </span>

        </div>

      </aside>


      {/* MAIN */}

      <main className="main-content">

        <header className="topbar">

          <div>

            <p className="eyebrow">
              AI LLM PLATFORM
            </p>

            <h1>{page}</h1>

          </div>


          <div className="environment">

            <span className="status-dot online" />

            System Online

          </div>

        </header>


        {/* CHAT */}

        {page === 'Chat' && (

          <section className="chat-panel">

            <div className="chat-header">

              <div>

                <h3>
                  AI Assistant
                </h3>

                <p>
                  Powered by Llama 3.2 through an OpenAI-compatible API
                </p>

              </div>


              <button
                type="button"
                className="secondary-button"
                onClick={clearChat}
              >
                Clear chat
              </button>

            </div>


            <div className="messages">

              {messages.map(
                (message, index) => (

                  <div
                    key={`${message.role}-${index}`}
                    className={`message-row ${message.role}`}
                  >

                    <div className="avatar">

                      {message.role === 'assistant'
                        ? 'AI'
                        : 'YOU'}

                    </div>


                    <div className="message">

                      <span>

                        {message.role === 'assistant'
                          ? 'AI Assistant'
                          : 'You'}

                      </span>


                      <p>
                        {message.content}
                      </p>

                    </div>

                  </div>

                ),
              )}


              {chatLoading && (

                <div className="message-row assistant">

                  <div className="avatar">
                    AI
                  </div>

                  <div className="message">

                    <span>
                      AI Assistant
                    </span>

                    <p className="thinking">
                      Thinking...
                    </p>

                  </div>

                </div>

              )}

            </div>


            {/* CHAT INPUT */}

            <form
              className="composer"
              onSubmit={chat}
            >

              <textarea
                value={msg}
                onChange={(e) =>
                  setMsg(e.target.value)
                }
                onKeyDown={handleChatKeyDown}
                placeholder="Ask about Kubernetes, AWS, Terraform, DevOps..."
              />


              <div className="composer-footer">

                <span>
                  Enter to send · Shift+Enter for new line · Llama 3.2 3B
                </span>


                <button
                  type="submit"
                  className="primary-button"
                  disabled={
                    chatLoading ||
                    !msg.trim()
                  }
                >
                  {chatLoading
                    ? 'Generating...'
                    : 'Send'}
                </button>

              </div>

            </form>

          </section>

        )}


        {/* DOCUMENTS */}

        {page === 'Documents' && (

          <section className="page-card">

            <div className="section-heading">

              <div className="section-icon">
                ▤
              </div>


              <div>

                <h3>
                  Add knowledge
                </h3>

                <p>
                  Add text to the RAG knowledge base.
                  The service will chunk, embed and
                  store it in PostgreSQL with pgvector.
                </p>

              </div>

            </div>


            <form
              className="form-stack"
              onSubmit={addDocument}
            >

              <label>

                Document title

                <input
                  value={title}
                  onChange={(e) =>
                    setTitle(
                      e.target.value,
                    )
                  }
                  placeholder="Example: Kubernetes Production Guide"
                />

              </label>


              <label>

                Document content

                <textarea
                  className="document-textarea"
                  value={content}
                  onChange={(e) =>
                    setContent(
                      e.target.value,
                    )
                  }
                  placeholder="Paste your document content here..."
                />

              </label>


              <div className="form-actions">

                <span className="form-status">
                  {documentStatus}
                </span>


                <button
                  type="submit"
                  className="primary-button"
                  disabled={
                    documentLoading ||
                    !title.trim() ||
                    !content.trim()
                  }
                >

                  {documentLoading
                    ? 'Indexing...'
                    : 'Chunk, embed & index'}

                </button>

              </div>

            </form>

          </section>

        )}


        {/* KNOWLEDGE BASE */}

        {page === 'Knowledge Base' && (

          <section className="page-card">

            <div className="section-heading">

              <div className="section-icon">
                ◫
              </div>


              <div>

                <h3>
                  Semantic search
                </h3>

                <p>
                  Search indexed documents using
                  vector similarity.
                </p>

              </div>

            </div>


            <form
              className="search-bar"
              onSubmit={search}
            >

              <input
                value={query}
                onChange={(e) =>
                  setQuery(
                    e.target.value,
                  )
                }
                placeholder="Search your knowledge base..."
              />


              <button
                type="submit"
                className="primary-button"
                disabled={
                  searchLoading ||
                  !query.trim()
                }
              >

                {searchLoading
                  ? 'Searching...'
                  : 'Search'}

              </button>

            </form>


            <div className="search-results">

              {results.length === 0 &&
                !searchLoading && (

                  <div className="empty-state">

                    <div>
                      ⌕
                    </div>

                    <h4>
                      No results to display
                    </h4>

                    <p>
                      Run a semantic search against
                      your indexed knowledge.
                    </p>

                  </div>

                )}


              {results.map(
                (result, index) => (

                  <article
                    className="result-card"
                    key={index}
                  >

                    <div className="result-heading">

                      <strong>

                        {result.document_title ||
                          'Knowledge result'}

                      </strong>


                      {typeof result.distance ===
                        'number' && (

                        <span>

                          Distance{' '}
                          {result.distance.toFixed(
                            4,
                          )}

                        </span>

                      )}

                    </div>


                    <p>
                      {result.content}
                    </p>

                  </article>

                ),
              )}

            </div>

          </section>

        )}


        {/* SYSTEM */}

        {page === 'System' && (

          <section>

            <div className="system-grid">

              <SystemCard
                title="API Gateway"
                description="Internal API routing"
                value="Connected"
              />


              <SystemCard
                title="AI Service"
                description="LLM orchestration"
                value="Online"
              />


              <SystemCard
                title="RAG Service"
                description="Retrieval pipeline"
                value="Online"
              />


              <SystemCard
                title="Vector Database"
                description="PostgreSQL + pgvector"
                value="Connected"
              />

            </div>


            <div className="architecture-card">

              <div>

                <p className="eyebrow">
                  INFERENCE
                </p>

                <h3>
                  OpenAI-compatible LLM endpoint
                </h3>

                <p>
                  The AI service communicates with
                  the configured inference endpoint
                  using the OpenAI-compatible chat
                  completions API.
                </p>

              </div>


              <div className="model-badge">

                <span>
                  MODEL
                </span>

                <strong>
                  Llama 3.2 · 3B
                </strong>

              </div>

            </div>


            <div className="architecture-card">

              <div>

                <p className="eyebrow">
                  PLATFORM ARCHITECTURE
                </p>

                <h3>
                  Kubernetes microservices
                </h3>

                <p>
                  Frontend → API Gateway → Auth /
                  AI / RAG → PostgreSQL + pgvector
                  → LLM inference
                </p>

              </div>


              <div className="model-badge">

                <span>
                  ENVIRONMENT
                </span>

                <strong>
                  Minikube
                </strong>

              </div>

            </div>

          </section>

        )}

      </main>

    </div>
  );
}


function SystemCard({
  title,
  description,
  value,
}) {
  return (
    <div className="system-card">

      <div className="system-card-top">

        <span className="status-dot online" />

        <span className="system-status">
          {value}
        </span>

      </div>

      <h3>
        {title}
      </h3>

      <p>
        {description}
      </p>

    </div>
  );
}


createRoot(
  document.getElementById('root'),
).render(
  <App />,
);