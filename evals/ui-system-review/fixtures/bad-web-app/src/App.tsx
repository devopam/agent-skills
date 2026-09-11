import { ThemeProvider, createTheme } from '@mui/material/styles';
import { ChakraProvider } from '@chakra-ui/react';
import { FeatureA } from './features/FeatureA';
import { FeatureB } from './features/FeatureB';

const muiTheme = createTheme();

export function App() {
  return (
    <ThemeProvider theme={muiTheme}>
      <ChakraProvider>
        <div style={{ width: '1200px', margin: '0 auto' }}>
          <FeatureA />
          <FeatureB />
        </div>
      </ChakraProvider>
    </ThemeProvider>
  );
}
