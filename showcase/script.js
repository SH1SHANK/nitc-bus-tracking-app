const root = document.documentElement;
const themeButton = document.querySelector('.theme-toggle');
const navButton = document.querySelector('.nav-toggle');
const nav = document.querySelector('.primary-nav');
const themeColor = document.querySelector('meta[name="theme-color"]');
const mobileMenu = matchMedia('(max-width: 640px)');
const systemTheme = matchMedia('(prefers-color-scheme: dark)');

function isDark() {
  return root.dataset.theme === 'dark' || (!root.dataset.theme && systemTheme.matches);
}

function updateThemeButton() {
  themeButton.setAttribute('aria-label', `Switch to ${isDark() ? 'light' : 'dark'} theme`);
  themeColor.content = isDark() ? '#101d29' : '#f7f8f5';
}

function closeMenu(returnFocus = false) {
  navButton.setAttribute('aria-expanded', 'false');
  navButton.querySelector('.sr-only').textContent = 'Open navigation';
  nav.classList.remove('is-open');
  if (mobileMenu.matches) nav.inert = true;
  if (returnFocus) navButton.focus();
}

function syncMenuMode() {
  nav.inert = mobileMenu.matches && navButton.getAttribute('aria-expanded') !== 'true';
  if (!mobileMenu.matches) {
    nav.classList.remove('is-open');
    navButton.setAttribute('aria-expanded', 'false');
  }
}

themeButton.addEventListener('click', () => {
  root.dataset.theme = isDark() ? 'light' : 'dark';
  try { localStorage.setItem('bustracker-theme', root.dataset.theme); } catch {}
  updateThemeButton();
});

systemTheme.addEventListener('change', () => {
  if (!root.dataset.theme) updateThemeButton();
});

navButton.addEventListener('click', () => {
  const open = navButton.getAttribute('aria-expanded') !== 'true';
  if (open) {
    navButton.setAttribute('aria-expanded', 'true');
    navButton.querySelector('.sr-only').textContent = 'Close navigation';
    nav.classList.add('is-open');
    nav.inert = false;
  } else closeMenu();
});

document.addEventListener('keydown', (event) => {
  if (event.key === 'Escape' && navButton.getAttribute('aria-expanded') === 'true') closeMenu(true);
});

nav.addEventListener('click', (event) => {
  if (event.target.closest('a[href^="#"]') && mobileMenu.matches) closeMenu();
});

mobileMenu.addEventListener('change', syncMenuMode);
syncMenuMode();
updateThemeButton();
document.querySelector('#year').textContent = new Date().getFullYear();

if (!matchMedia('(prefers-reduced-motion: reduce)').matches && 'IntersectionObserver' in window) {
  root.classList.add('motion-ready');
  const revealObserver = new IntersectionObserver((entries, observer) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        entry.target.classList.add('is-visible');
        observer.unobserve(entry.target);
      }
    });
  }, { threshold: 0.14 });
  document.querySelectorAll('[data-reveal]').forEach((element) => revealObserver.observe(element));
}
