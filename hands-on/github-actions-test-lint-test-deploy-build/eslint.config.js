import eslintReact from '@eslint-react/eslint-plugin';

export default [
  {
    files: ['**/*.{js,jsx}'],
    ...eslintReact.configs.recommended,
    languageOptions: {
      parserOptions: {
        ecmaFeatures: { jsx: true },
      },
    },
  },
  {
    files: ['**/*.{js,jsx}'],
    rules: {
      semi: ['error', 'always'],
    },
  },
];
