/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly REACT_APP_API_SERVER: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
