import type { Metadata } from "next";
import { AppProviders } from "../components/app-providers";

export const metadata: Metadata = {
  title: "The Forge",
  description: "Track workouts and progression with The Forge"
};

type RootLayoutProps = {
  children: React.ReactNode;
};

export default function RootLayout({ children }: RootLayoutProps) {
  return (
    <html lang="en">
      <body>
        <AppProviders>{children}</AppProviders>
      </body>
    </html>
  );
}
