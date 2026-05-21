"use client";

import { CssBaseline, ThemeProvider } from "@mui/material";
import { ReactNode } from "react";
import { forgeTheme } from "../theme";

type AppProvidersProps = {
  children: ReactNode;
};

export function AppProviders({ children }: AppProvidersProps) {
  return (
    <ThemeProvider theme={forgeTheme}>
      <CssBaseline />
      {children}
    </ThemeProvider>
  );
}
