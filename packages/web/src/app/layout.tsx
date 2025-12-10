import type { Metadata } from 'next'
import './globals.css'
import { Footer } from '@dpip/common/components/footer';

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
    <html lang="zh-TW" className="h-full overflow-hidden">
      <body className="h-full m-0 p-0 relative overflow-hidden">
        {children}
        <Footer />
      </body>
    </html>
  )
}
