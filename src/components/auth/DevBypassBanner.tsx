/**
 * DevBypassBanner - Visual indicator for development authentication bypass mode
 * 
 * This component displays a yellow warning banner when authentication is bypassed
 * in development mode. It's only shown when DEV_BYPASS_AUTH is enabled.
 */
export const DevBypassBanner = () => {
  return (
    <div 
      className="fixed top-4 right-4 z-50 bg-yellow-500/10 border border-yellow-500 text-yellow-700 dark:text-yellow-400 px-4 py-2 rounded-lg text-sm font-medium"
      role="alert"
      aria-live="polite"
    >
      🔓 Dev Mode: Auth Bypassed
    </div>
  );
};
