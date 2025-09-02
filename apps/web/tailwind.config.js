/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./src/**/*.{ts,tsx,js,jsx}"],
  theme: {
    extend: {
      colors: {
        ke: {
          bg: "#ffffff",
          surface: "#ffffff",
          text: "#0B1220",
          subtext: "#475569",
          border: "#E5E7EB",
          primary: {
            50:"#EEF5FF",100:"#D9E9FF",200:"#B6D4FF",300:"#8CB7FF",
            400:"#5F95FF",500:"#3B82F6",600:"#2563EB",700:"#1D4ED8",
            800:"#1E40AF",900:"#1E3A8A"
          }
        }
      },
      borderRadius: { xl:"14px", lg:"12px", md:"10px" },
      container: { center:true, padding:"1rem", screens:{ lg:"960px", xl:"1120px", "2xl":"1200px" } }
    },
  },
  plugins: [],
};
