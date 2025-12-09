import type { Metadata } from 'next'
import './globals.css'

export const metadata: Metadata = {
  title: 'DPIP',
  description: 'DPIP - Disaster Prevention Information Platform',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="zh-TW" className="h-full">
      <body className="h-full m-0 p-0">{children}</body>
    </html>
  )
}
