/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        forestGreen: {
          50: '#f2f8f4',
          100: '#e1f0e4',
          500: '#2e7d32',
          600: '#1b5e20',
          700: '#144718',
          800: '#0e3111',
        },
        accentOrange: {
          500: '#e65100',
          600: '#bf4300',
        },
        cream: '#faf7f2',
      },
      fontFamily: {
        sans: ['Cairo', 'system-ui', '-apple-system', 'sans-serif'],
      },
    },
  },
  plugins: [],
}
