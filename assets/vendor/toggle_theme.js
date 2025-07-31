// Dark/Light Mode theme toggle lightly adjusted from:
// https://github.com/aiwaiwa/phoenix_dark_mode/blob/main/dark_mode.js

const localStorageKey = "theme";

export const isDark = () => {
  if (localStorage.getItem(localStorageKey) === "dark") return true;
  if (localStorage.getItem(localStorageKey) === "light") return false;
  return window.matchMedia("(prefers-color-scheme: dark)").matches;
};

const setupToggleTheme = () => {
  toggleVisibility = (dark) => {
    const themeToggleDarkIcon = document.getElementById("theme-toggle-dark-icon");
    const themeToggleLightIcon = document.getElementById("theme-toggle-light-icon");
    if (themeToggleDarkIcon == null || themeToggleLightIcon == null) return;
    const show = dark ? themeToggleDarkIcon : themeToggleLightIcon;
    const hide = dark ? themeToggleLightIcon : themeToggleDarkIcon;
    show.classList.remove("hidden", "text-transparent");
    hide.classList.add("hidden", "text-transparent");
    if (dark) {
      document.documentElement.classList.add("dark");
    } else {
      document.documentElement.classList.remove("dark");
    }
    try {
      localStorage.setItem(localStorageKey, dark ? "dark" : "light");
      // Dispatch custom event for same-tab listeners
      window.dispatchEvent(new CustomEvent("themeChanged", { detail: { isDark: dark } }));
    } catch (_err) {}
  };
  toggleVisibility(isDark());
  document.getElementById("theme-toggle").addEventListener("click", function () {
    toggleVisibility(!isDark());
  });
};

const toggleThemeHook = {
  mounted() {
    setupToggleTheme();
  },
  updated() {},
};

export default toggleThemeHook;
