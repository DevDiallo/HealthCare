import { createContext, useContext, useMemo, useState, type PropsWithChildren } from 'react'

type AppContextValue = {
  globalSearch: string
  setGlobalSearch: (value: string) => void
}

const AppContext = createContext<AppContextValue | null>(null)

export function AppProvider({ children }: PropsWithChildren) {
  const [globalSearch, setGlobalSearch] = useState('')
  const value = useMemo(() => ({ globalSearch, setGlobalSearch }), [globalSearch])
  return <AppContext.Provider value={value}>{children}</AppContext.Provider>
}

export function useAppContext() {
  const ctx = useContext(AppContext)
  if (!ctx) {
    throw new Error('useAppContext must be used inside AppProvider')
  }
  return ctx
}
