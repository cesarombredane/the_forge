import { createTheme } from "@mui/material/styles";

export const forgeTheme = createTheme({
  palette: {
    mode: "light",
    primary: {
      main: "#0b5fff"
    },
    secondary: {
      main: "#ff7a00"
    },
    background: {
      default: "#f7f8fc",
      paper: "#ffffff"
    }
  },
  shape: {
    borderRadius: 12
  },
  typography: {
    fontFamily: "'Source Sans 3', 'Segoe UI', sans-serif"
  }
});
