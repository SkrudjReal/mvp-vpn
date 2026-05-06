import { useEffect, useMemo, useState } from 'react';
import type { ComponentType, ReactNode } from 'react';
import {
  ArrowLeft,
  Check,
  ChevronRight,
  Clock3,
  Copy,
  CreditCard,
  Eye,
  EyeOff,
  FileText,
  Gift,
  Home,
  Import,
  LogOut,
  Megaphone,
  Moon,
  RefreshCw,
  Send,
  ShieldCheck,
  Sparkles,
  Sun,
  Ticket,
  User,
  WalletCards,
} from 'lucide-react';
import { CosmicBackground } from './components/CosmicBackground';
import { HeroPanel } from './components/HeroPanel';

type Theme = 'light' | 'dark';
type AuthScreen = 'login' | 'generate';
type Page = 'home' | 'tariffs' | 'invoices' | 'referral' | 'import' | 'invoice-detail';

type UserEntity = {
  id: string;
  refCode: string;
  subscriptionStatus: 'active' | 'inactive';
  subscriptionUntil: string | null;
  createdAt: string;
  importedAt: string | null;
};

type Tariff = {
  id: string;
  title: string;
  duration: string;
  devices: number;
  traffic: string;
  price: number;
  popular: boolean;
};

type Invoice = {
  id: string;
  tariffId: string;
  title: string;
  amount: number;
  status: 'pending' | 'paid' | 'cancelled';
  createdAt: string;
};

type DashboardData = {
  user: UserEntity;
  invoices: Invoice[];
  tariffs: Tariff[];
};

const defaultTariffs: Tariff[] = [
  { id: 'month', title: 'Подписка на 30 дней', duration: '1 месяц', devices: 3, traffic: '∞', price: 149, popular: true },
  { id: 'quarter', title: 'Подписка на 90 дней', duration: '3 месяца', devices: 5, traffic: '∞', price: 399, popular: false },
  { id: 'year', title: 'Подписка на 365 дней', duration: '12 месяцев', devices: 8, traffic: '∞', price: 1290, popular: false },
];

export default function App() {
  const [systemTheme, setSystemTheme] = useState<Theme>(() => getSystemTheme());
  const [themeOverride, setThemeOverride] = useState<Theme | null>(() => getStoredTheme());
  const [authScreen, setAuthScreen] = useState<AuthScreen>('login');
  const [user, setUser] = useState<UserEntity | null>(null);
  const [data, setData] = useState<DashboardData | null>(null);
  const [page, setPage] = useState<Page>('home');
  const [selectedInvoiceId, setSelectedInvoiceId] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [toast, setToast] = useState<string | null>(null);
  const theme = themeOverride ?? systemTheme;

  useEffect(() => {
    const root = document.documentElement;
    root.dataset.theme = theme;
    root.style.colorScheme = theme;
  }, [theme]);

  useEffect(() => {
    document.body.dataset.view = user ? 'dashboard' : 'auth';
    return () => {
      delete document.body.dataset.view;
    };
  }, [user]);

  useEffect(() => {
    const query = window.matchMedia('(prefers-color-scheme: dark)');
    const handleChange = (event: MediaQueryListEvent) => setSystemTheme(event.matches ? 'dark' : 'light');
    query.addEventListener('change', handleChange);
    return () => query.removeEventListener('change', handleChange);
  }, []);

  useEffect(() => {
    void boot();
  }, []);

  async function boot() {
    setLoading(true);
    try {
      const session = await api<{ user: UserEntity | null }>('/api/session');
      if (session.user) {
        setUser(session.user);
        await refreshDashboard();
      }
    } finally {
      setLoading(false);
    }
  }

  async function refreshDashboard() {
    const dashboard = await api<DashboardData>('/api/dashboard');
    setData(dashboard);
    setUser(dashboard.user);
  }

  function toggleTheme() {
    const nextTheme = theme === 'dark' ? 'light' : 'dark';
    setThemeOverride(nextTheme);
    localStorage.setItem('noda-theme', nextTheme);
  }

  function notify(message: string) {
    setToast(message);
    window.setTimeout(() => setToast(null), 2400);
  }

  async function logout() {
    await api('/api/logout', { method: 'POST' });
    setUser(null);
    setData(null);
    setPage('home');
    setSelectedInvoiceId(null);
    setAuthScreen('login');
  }

  async function createInvoice(tariffId: string) {
    const response = await api<{ invoice: Invoice; paymentEnabled: boolean }>('/api/invoices', {
      method: 'POST',
      body: JSON.stringify({ tariffId }),
    });
    await refreshDashboard();
    setSelectedInvoiceId(response.invoice.id);
    setPage('invoice-detail');
    notify('Счёт создан. Оплата пока не подключена.');
  }

  async function importSubscription(importCode: string) {
    const response = await api<{ user: UserEntity; imported: boolean }>('/api/import', {
      method: 'POST',
      body: JSON.stringify({ importCode }),
    });
    setUser(response.user);
    await refreshDashboard();
    notify('Импорт выполнен. Тестовая подписка активирована на 30 дней.');
  }

  const hero = authScreen === 'login'
    ? {
        eyebrow: 'private tunnel',
        titleTop: 'С возвращением,',
        titleAccent: 'noda user',
        description: 'Ни почты, ни паролей. Только короткая фраза, которую вы записали при первой настройке Noda VPN.',
      }
    : {
        eyebrow: 'new access',
        titleTop: 'Новый ключ,',
        titleAccent: 'чистый маршрут',
        description: 'Шесть слов станут вашим приватным доступом. Запишите фразу: восстановить её невозможно.',
      };

  if (loading) {
    return (
      <main className="app-shell">
        <CosmicBackground />
        <div className="boot-loader">
          <ShieldCheck size={32} />
          <span>noda.</span>
        </div>
      </main>
    );
  }

  if (user && data) {
    return (
      <DashboardShell
        data={data}
        page={page}
        theme={theme}
        selectedInvoiceId={selectedInvoiceId}
        onPage={setPage}
        onSelectInvoice={(id) => {
          setSelectedInvoiceId(id);
          setPage('invoice-detail');
        }}
        onTheme={toggleTheme}
        onLogout={logout}
        onCreateInvoice={createInvoice}
        onImport={importSubscription}
        onToast={notify}
      >
        {page === 'home' && <HomePage data={data} onPage={setPage} onCreateInvoice={createInvoice} />}
        {page === 'tariffs' && <TariffsPage tariffs={data.tariffs} onCreateInvoice={createInvoice} />}
        {page === 'invoices' && <InvoicesPage invoices={data.invoices} onSelectInvoice={(id) => {
          setSelectedInvoiceId(id);
          setPage('invoice-detail');
        }} />}
        {page === 'invoice-detail' && <InvoiceDetail invoice={data.invoices.find((invoice) => invoice.id === selectedInvoiceId) ?? data.invoices[0]} onBack={() => setPage('invoices')} onToast={notify} />}
        {page === 'referral' && <ReferralPage user={data.user} onToast={notify} />}
        {page === 'import' && <ImportPage onImport={importSubscription} />}
      </DashboardShell>
    );
  }

  return (
    <main className="app-shell">
      <CosmicBackground />
      <div className="page-actions">
        <a className="support-link" href="https://t.me/" target="_blank" rel="noreferrer">
          Поддержка
        </a>
        <button
          className="theme-toggle"
          type="button"
          aria-label={theme === 'dark' ? 'Включить светлую тему' : 'Включить тёмную тему'}
          onClick={toggleTheme}
        >
          {theme === 'dark' ? <Sun size={18} /> : <Moon size={18} />}
        </button>
      </div>
      <HeroPanel {...hero} />
      <section className="form-pane">
        <div className="auth-stack">
          {authScreen === 'login' ? (
            <LoginForm
              onGenerate={() => setAuthScreen('generate')}
              onLogin={async (loggedUser) => {
                setUser(loggedUser);
                await refreshDashboard();
              }}
            />
          ) : (
            <GenerateForm
              onBack={() => setAuthScreen('login')}
              onReady={async (generatedUser) => {
                setUser(generatedUser);
                await refreshDashboard();
              }}
            />
          )}
          <p className="security-note">
            <ShieldCheck size={18} />
            <span>Ваш ключ хранится в защищённом виде<br />и используется только для входа в аккаунт.</span>
          </p>
        </div>
      </section>
      {toast && <div className="toast">{toast}</div>}
    </main>
  );
}

function LoginForm({ onGenerate, onLogin }: { onGenerate: () => void; onLogin: (user: UserEntity) => Promise<void> }) {
  const [phrase, setPhrase] = useState('');
  const [show, setShow] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const wordCount = useMemo(
    () => (phrase.trim() ? phrase.trim().split(/[\s-]+/).filter(Boolean).length : 0),
    [phrase],
  );

  async function submit() {
    setBusy(true);
    setError(null);
    try {
      const response = await api<{ user: UserEntity }>('/api/auth/login', {
        method: 'POST',
        body: JSON.stringify({ phrase }),
      });
      await onLogin(response.user);
    } catch (err) {
      setError(readError(err, 'Фраза не найдена. Проверьте 6 слов и попробуйте ещё раз.'));
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="auth-card">
      <div className="form-top">
        <div className="tabs" role="tablist" aria-label="Access mode">
          <button className="active" type="button">Вход</button>
          <button type="button" onClick={onGenerate}>Новый ключ</button>
        </div>
      </div>

      <label className="field-block">
        <span className="field-label">
          <span>Ключевая фраза</span>
          <b>{wordCount}<i>/</i>6</b>
        </span>
        <span className="phrase-field">
          <input
            type={show ? 'text' : 'password'}
            value={phrase}
            onChange={(event) => setPhrase(event.target.value)}
            onKeyDown={(event) => {
              if (event.key === 'Enter') void submit();
            }}
            placeholder="noda-orbit-velvet-north-silent-relay"
            autoComplete="off"
            spellCheck={false}
          />
          <button type="button" aria-label={show ? 'Скрыть' : 'Показать'} onClick={() => setShow((value) => !value)}>
            {show ? <EyeOff size={20} /> : <Eye size={20} />}
          </button>
        </span>
      </label>

      {error && <p className="form-error">{error}</p>}

      <button className="primary-action" type="button" disabled={busy} onClick={submit}>
        <span>{busy ? 'Проверяем...' : 'Войти'}</span>
        <ChevronRight size={17} />
      </button>

      <div className="divider"><span>или</span></div>

      <button className="secondary-action" type="button" onClick={onGenerate}>
        <Sparkles size={17} />
        <span>Сгенерировать новый ключ</span>
        <ChevronRight size={17} />
      </button>
    </div>
  );
}

function GenerateForm({ onBack, onReady }: { onBack: () => void; onReady: (user: UserEntity) => Promise<void> }) {
  const [phrase, setPhrase] = useState<string | null>(null);
  const [user, setUser] = useState<UserEntity | null>(null);
  const [copied, setCopied] = useState(false);
  const [busy, setBusy] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    void generate();
  }, []);

  async function generate() {
    setBusy(true);
    setError(null);
    try {
      const response = await api<{ user: UserEntity; phrase: string }>('/api/auth/generate', { method: 'POST' });
      setPhrase(response.phrase);
      setUser(response.user);
    } catch (err) {
      setError(readError(err, 'Не удалось создать ключ.'));
    } finally {
      setBusy(false);
    }
  }

  async function copy() {
    if (!phrase) return;
    await navigator.clipboard?.writeText(phrase);
    setCopied(true);
    window.setTimeout(() => setCopied(false), 1500);
  }

  return (
    <div className="auth-card generate-card">
      <div className="form-top">
        <div className="tabs" role="tablist" aria-label="Access mode">
          <button type="button" onClick={onBack}>Вход</button>
          <button className="active" type="button">Новый ключ</button>
        </div>

        <button className="back-link" type="button" onClick={onBack}>
          <ArrowLeft size={15} />
          Назад
        </button>
      </div>

      <div className="generate-title">
        <span>private key</span>
        <h2>Новый доступ</h2>
      </div>

      {busy && <div className="phrase-loading">Генерируем ключ...</div>}
      {error && <p className="form-error">{error}</p>}

      {phrase && (
        <div className="phrase-reveal" aria-label="Generated access phrase">
          {phrase.split('-').map((word, index) => (
            <span className="word-chip" key={`${word}-${index}`}>
              <small>{String(index + 1).padStart(2, '0')}</small>
              {word}
            </span>
          ))}
        </div>
      )}

      <div className="small-actions">
        <button type="button" onClick={generate} disabled={busy}>
          <RefreshCw size={17} />
          Обновить
        </button>
        <button type="button" onClick={copy} disabled={!phrase}>
          {copied ? <Check size={17} /> : <Copy size={17} />}
          {copied ? 'Скопировано' : 'Копировать'}
        </button>
      </div>

      <button className="primary-action" type="button" disabled={!user} onClick={() => user && onReady(user)}>
        <span>Сохранить и войти</span>
        <ChevronRight size={17} />
      </button>

      <p className="note">Запишите фразу в надёжном месте. Это единственный ключ к вашему туннелю.</p>
    </div>
  );
}

function DashboardShell({
  data,
  page,
  theme,
  selectedInvoiceId,
  children,
  onPage,
  onSelectInvoice,
  onTheme,
  onLogout,
  onCreateInvoice,
  onImport,
  onToast,
}: {
  data: DashboardData;
  page: Page;
  theme: Theme;
  selectedInvoiceId: string | null;
  children: ReactNode;
  onPage: (page: Page) => void;
  onSelectInvoice: (id: string) => void;
  onTheme: () => void;
  onLogout: () => void;
  onCreateInvoice: (tariffId: string) => Promise<void>;
  onImport: (importCode: string) => Promise<void>;
  onToast: (message: string) => void;
}) {
  const navItems = [
    { page: 'home' as const, label: 'Главная', icon: Home },
    { page: 'tariffs' as const, label: 'Тарифы', icon: CreditCard },
    { page: 'invoices' as const, label: 'Счета', icon: FileText },
    { page: 'referral' as const, label: 'Рефералы', icon: Gift },
    { page: 'import' as const, label: 'Импорт', icon: Import },
  ];

  return (
    <main className="dashboard-shell">
      <CosmicBackground />
      <header className="dash-header">
        <button className="dash-logo" type="button" onClick={() => onPage('home')}>
          <span><img src="/icon.png" alt="" /></span>
          <b>noda.</b>
        </button>

        <div className="dash-actions">
          <button className="user-chip" type="button" onClick={async () => {
            await navigator.clipboard?.writeText(data.user.id);
            onToast('ID аккаунта скопирован.');
          }}>
            <User size={16} />
            <span>{shortId(data.user.id)}</span>
          </button>
          <button className="theme-toggle dash-theme" type="button" onClick={onTheme}>
            {theme === 'dark' ? <Sun size={18} /> : <Moon size={18} />}
          </button>
          <button className="dash-icon-button" type="button" title="Выйти" onClick={onLogout}>
            <LogOut size={18} />
          </button>
        </div>
      </header>

      <div className="dashboard-grid">
        <aside className="dash-sidebar">
          <nav>
            {navItems.map((item) => {
              const Icon = item.icon;
              const active = page === item.page || (page === 'invoice-detail' && item.page === 'invoices');
              return (
                <button className={active ? 'active' : ''} key={item.page} type="button" onClick={() => onPage(item.page)}>
                  <Icon size={18} />
                  <span>{item.label}</span>
                </button>
              );
            })}
          </nav>
        </aside>

        <section className="dash-content">
          {children}
          <MobileNav
            page={page}
            onPage={onPage}
            onCreateInvoice={onCreateInvoice}
            onImport={onImport}
            selectedInvoiceId={selectedInvoiceId}
            onSelectInvoice={onSelectInvoice}
          />
        </section>
      </div>
    </main>
  );
}

function HomePage({ data, onPage, onCreateInvoice }: { data: DashboardData; onPage: (page: Page) => void; onCreateInvoice: (tariffId: string) => Promise<void> }) {
  const pending = data.invoices.filter((invoice) => invoice.status === 'pending').length;
  const active = data.user.subscriptionStatus === 'active';

  return (
    <div className="dash-page">
      <PageTitle title="Главная" subtitle="Ваш аккаунт, подписки и настройки" />

      <button className="import-banner" type="button" onClick={() => onPage('import')}>
        <Send size={22} />
        <span>
          <b>Уже пользуетесь Noda VPN в Telegram?</b>
          <small>Перенесите подписку из бота на сайт в один клик.</small>
        </span>
        <ChevronRight size={18} />
      </button>

      <section className="hero-card account-card">
        <div className="account-emblem"><ShieldCheck size={48} /></div>
        <div>
          <p className="kicker">Ваша подписка</p>
          <h2>{active ? 'Активна' : 'Неактивна'}</h2>
          <p>{active ? `Доступ действует до ${formatDate(data.user.subscriptionUntil)}` : 'Оформите подписку, чтобы пользоваться свободным интернетом.'}</p>
        </div>
        <button className="dash-primary" type="button" onClick={() => active ? onPage('tariffs') : onCreateInvoice('month')}>
          {active ? 'Продлить' : 'Купить подписку'}
          <ChevronRight size={16} />
        </button>
      </section>

      <section className="stat-grid">
        <StatCard icon={FileText} label="Счетов" value={String(data.invoices.length)} />
        <StatCard icon={Clock3} label="Ожидают оплаты" value={String(pending)} />
        <StatCard icon={Ticket} label="Реф. код" value={data.user.refCode} />
      </section>

      <section className="tile-grid">
        <a className="dash-tile" href="https://t.me/" target="_blank" rel="noreferrer">
          <WalletCards size={20} />
          <h3>Поддержка</h3>
          <p>Telegram</p>
        </a>
        <a className="dash-tile" href="https://t.me/" target="_blank" rel="noreferrer">
          <Megaphone size={20} />
          <h3>Канал Noda</h3>
          <p>Telegram</p>
        </a>
      </section>
    </div>
  );
}

function TariffsPage({ tariffs, onCreateInvoice }: { tariffs: Tariff[]; onCreateInvoice: (tariffId: string) => Promise<void> }) {
  return (
    <div className="dash-page">
      <PageTitle title="Тарифы" subtitle="Выберите срок подписки. Оплата пока будет создана как ожидающий счёт." />
      <section className="tariff-grid">
        {tariffs.map((tariff) => (
          <article className={tariff.popular ? 'tariff-card popular' : 'tariff-card'} key={tariff.id}>
            {tariff.popular && <span className="badge">популярно</span>}
            <h2>{tariff.duration}</h2>
            <p>{tariff.title}</p>
            <strong>{tariff.price} ₽</strong>
            <dl>
              <div><dt>Устройств</dt><dd>{tariff.devices}</dd></div>
              <div><dt>Трафик</dt><dd>{tariff.traffic}</dd></div>
            </dl>
            <button className="dash-primary" type="button" onClick={() => onCreateInvoice(tariff.id)}>
              Создать счёт
              <ChevronRight size={16} />
            </button>
          </article>
        ))}
      </section>
    </div>
  );
}

function InvoicesPage({ invoices, onSelectInvoice }: { invoices: Invoice[]; onSelectInvoice: (id: string) => void }) {
  const totalPaid = invoices.filter((invoice) => invoice.status === 'paid').reduce((sum, invoice) => sum + invoice.amount, 0);

  return (
    <div className="dash-page">
      <PageTitle title="Счета" subtitle="Все ваши платежи и счета в одном месте" />
      <section className="stat-grid">
        <StatCard icon={FileText} label="Всего счетов" value={String(invoices.length)} />
        <StatCard icon={CreditCard} label="Оплачено" value={`${totalPaid} ₽`} />
        <StatCard icon={Clock3} label="Последний счёт" value={invoices[0] ? formatDate(invoices[0].createdAt) : 'нет'} />
      </section>

      <section className="table-card">
        <div className="invoice-row header">
          <span>Номер</span>
          <span>Дата</span>
          <span>Подписка</span>
          <span>Сумма</span>
          <span>Статус</span>
        </div>
        {invoices.length === 0 ? (
          <div className="empty-state">Счетов пока нет. Выберите тариф, чтобы создать первый счёт.</div>
        ) : invoices.map((invoice) => (
          <button className="invoice-row" key={invoice.id} type="button" onClick={() => onSelectInvoice(invoice.id)}>
            <span className="mono">№ {invoice.id.slice(0, 8)}</span>
            <span>{formatDate(invoice.createdAt)}</span>
            <span>{invoice.title}</span>
            <span>{invoice.amount} ₽</span>
            <StatusBadge status={invoice.status} />
          </button>
        ))}
      </section>
    </div>
  );
}

function InvoiceDetail({ invoice, onBack, onToast }: { invoice?: Invoice; onBack: () => void; onToast: (message: string) => void }) {
  if (!invoice) {
    return (
      <div className="dash-page">
        <button className="back-link" type="button" onClick={onBack}><ArrowLeft size={15} />К списку</button>
        <div className="empty-state">Счёт не найден.</div>
      </div>
    );
  }

  return (
    <div className="dash-page narrow">
      <button className="back-link" type="button" onClick={onBack}><ArrowLeft size={15} />К списку</button>
      <PageTitle title={`Счёт на ${invoice.amount} ₽`} subtitle={`Создан ${formatDateTime(invoice.createdAt)}`} />
      <section className="hero-card invoice-detail">
        <StatusBadge status={invoice.status} />
        <h2>{invoice.title}</h2>
        <dl>
          <div><dt>Срок</dt><dd>{invoice.tariffId === 'month' ? '1 месяц' : invoice.tariffId === 'quarter' ? '3 месяца' : '12 месяцев'}</dd></div>
          <div><dt>Устройств</dt><dd>{invoice.tariffId === 'month' ? 3 : invoice.tariffId === 'quarter' ? 5 : 8}</dd></div>
          <div><dt>Трафик</dt><dd>∞</dd></div>
        </dl>
      </section>
      <section className="hero-card invoice-total">
        <span>К оплате</span>
        <strong>{invoice.amount} ₽</strong>
      </section>
      <button className="dash-primary payment-disabled" type="button" onClick={() => onToast('Оплата пока не подключена.')}>
        Перейти к оплате
        <ChevronRight size={16} />
      </button>
    </div>
  );
}

function ReferralPage({ user, onToast }: { user: UserEntity; onToast: (message: string) => void }) {
  const link = `${window.location.origin}/?ref=${user.refCode}`;
  return (
    <div className="dash-page narrow">
      <PageTitle title="Реферальная программа" subtitle="Приглашайте друзей и получайте бонусные дни после запуска промо-логики." />
      <section className="hero-card referral-card">
        <Gift size={36} />
        <h2>{user.refCode}</h2>
        <p>{link}</p>
        <button className="dash-primary" type="button" onClick={async () => {
          await navigator.clipboard?.writeText(link);
          onToast('Реферальная ссылка скопирована.');
        }}>
          <Copy size={16} />
          Скопировать ссылку
        </button>
      </section>
      <section className="info-list">
        <h2>Как это работает</h2>
        <p>Друг регистрируется по вашей ссылке. После оплаты подписки бонус будет начислен автоматически.</p>
        <h2>Условия программы</h2>
        <p>Начисление бонусов включим после подключения оплаты. Сейчас раздел готов визуально и функционально для копирования ссылки.</p>
      </section>
    </div>
  );
}

function ImportPage({ onImport }: { onImport: (importCode: string) => Promise<void> }) {
  const [code, setCode] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function submit() {
    setBusy(true);
    setError(null);
    try {
      await onImport(code);
    } catch (err) {
      setError(readError(err, 'Введите код импорта из Telegram-бота.'));
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="dash-page narrow">
      <PageTitle title="Импорт подписок из Telegram-бота" subtitle="Введите код из бота, чтобы привязать существующую подписку к сайту." />
      <section className="hero-card import-card">
        <Import size={34} />
        <label className="field-block">
          <span className="field-label"><span>Код импорта</span></span>
          <span className="phrase-field">
            <input value={code} onChange={(event) => setCode(event.target.value)} placeholder="TG-NODA-1234" />
          </span>
        </label>
        {error && <p className="form-error">{error}</p>}
        <button className="dash-primary" type="button" disabled={busy} onClick={submit}>
          {busy ? 'Импортируем...' : 'Импортировать'}
          <ChevronRight size={16} />
        </button>
      </section>
      <section className="info-list">
        <h2>Как это работает</h2>
        <p>Сайт сохраняет факт импорта в базе и привязывает подписку к текущему аккаунту.</p>
        <h2>Условия импорта</h2>
        <p>Для MVP любой код длиннее 4 символов активирует тестовую подписку на 30 дней.</p>
      </section>
    </div>
  );
}

function MobileNav(_: {
  page: Page;
  onPage: (page: Page) => void;
  onCreateInvoice: (tariffId: string) => Promise<void>;
  onImport: (importCode: string) => Promise<void>;
  selectedInvoiceId: string | null;
  onSelectInvoice: (id: string) => void;
}) {
  return null;
}

function PageTitle({ title, subtitle }: { title: string; subtitle: string }) {
  return (
    <div className="page-title">
      <h1>{title}</h1>
      <p>{subtitle}</p>
    </div>
  );
}

function StatCard({ icon: Icon, label, value }: { icon: ComponentType<{ size?: number }>; label: string; value: string }) {
  return (
    <article className="stat-card">
      <span><Icon size={18} /></span>
      <div>
        <p>{label}</p>
        <strong>{value}</strong>
      </div>
    </article>
  );
}

function StatusBadge({ status }: { status: Invoice['status'] }) {
  const label = status === 'paid' ? 'Оплачен' : status === 'cancelled' ? 'Отменён' : 'Ожидает оплаты';
  return <span className={`status-badge ${status}`}>{label}</span>;
}

function getSystemTheme(): Theme {
  if (typeof window === 'undefined') return 'dark';
  return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
}

function getStoredTheme(): Theme | null {
  if (typeof window === 'undefined') return null;
  const stored = localStorage.getItem('noda-theme');
  if (stored === 'light' || stored === 'dark') return stored;
  return null;
}

async function api<T = unknown>(path: string, init: RequestInit = {}): Promise<T> {
  const response = await fetch(path, {
    credentials: 'include',
    headers: {
      'Content-Type': 'application/json',
      ...(init.headers || {}),
    },
    ...init,
  });
  const payload = await response.json().catch(() => ({}));
  if (!response.ok) {
    throw new Error(payload.error || 'request_failed');
  }
  return payload as T;
}

function readError(error: unknown, fallback: string) {
  if (!(error instanceof Error)) return fallback;
  const messages: Record<string, string> = {
    invalid_phrase: 'Фраза не найдена. Проверьте 6 слов и попробуйте ещё раз.',
    phrase_must_have_6_words: 'Ключевая фраза должна состоять из 6 слов.',
    import_code_required: 'Введите код импорта из Telegram-бота.',
  };
  return messages[error.message] || fallback;
}

function shortId(id: string) {
  return id.replace(/^usr_/, '').slice(0, 10);
}

function formatDate(value: string | null) {
  if (!value) return 'нет';
  return new Intl.DateTimeFormat('ru-RU', { day: 'numeric', month: 'long', year: 'numeric' }).format(new Date(value));
}

function formatDateTime(value: string) {
  return new Intl.DateTimeFormat('ru-RU', {
    day: 'numeric',
    month: 'long',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  }).format(new Date(value));
}
