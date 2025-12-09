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
    <html lang="zh-TW">
      <body>{children}</body>
    </html>
  )
}
