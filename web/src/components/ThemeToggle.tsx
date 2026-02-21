import { Monitor, Moon, Sun } from 'lucide-react'
import { useEffect, useState } from 'react'

type Theme = 'light' | 'dark' | 'system'

function getStoredTheme(): Theme {
  if (typeof window === 'undefined') return 'system'
  const stored = localStorage.getItem('theme')
  if (stored === 'light' || stored === 'dark') return stored
  return 'system'
}

function applyTheme(theme: Theme) {
  const root = document.documentElement
  if (theme === 'dark') {
    root.classList.add('dark')
    localStorage.setItem('theme', 'dark')
  } else if (theme === 'light') {
    root.classList.remove('dark')
    localStorage.setItem('theme', 'light')
  } else {
    const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches
    root.classList.toggle('dark', prefersDark)
    localStorage.removeItem('theme')
  }
}

const THEMES: Array<{ value: Theme; icon: typeof Sun; label: string }> = [
  { value: 'light', icon: Sun, label: 'Light' },
  { value: 'dark', icon: Moon, label: 'Dark' },
  { value: 'system', icon: Monitor, label: 'System' },
]

export function ThemeToggle() {
  const [theme, setTheme] = useState<Theme>('system')

  useEffect(() => {
    setTheme(getStoredTheme())
  }, [])

  useEffect(() => {
    applyTheme(theme)
  }, [theme])

  const cycleTheme = () => {
    const idx = THEMES.findIndex((t) => t.value === theme)
    const next = THEMES[(idx + 1) % THEMES.length]
    setTheme(next.value)
  }

  const current = THEMES.find((t) => t.value === theme) ?? THEMES[2]
  const Icon = current.icon

  return (
    <button
      onClick={cycleTheme}
      className="p-2 rounded-md text-muted-foreground hover:text-foreground hover:bg-accent transition-colors"
      aria-label={`Switch theme (current: ${current.label})`}
      title={`Theme: ${current.label}`}
    >
      <Icon className="size-6" />
    </button>
  )
}
