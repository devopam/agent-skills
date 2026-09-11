Web pack confirmed. Evidence:

- `package.json` depends on both `@mui/material` and `@chakra-ui/react`.
- `src/App.tsx` wraps both `ThemeProvider` (MUI) and `ChakraProvider`.
- Feature A imports MUI `Button`; feature B imports Chakra `Button` for the
  same primary-action role.

User: "Why does our UI feel inconsistent?"
