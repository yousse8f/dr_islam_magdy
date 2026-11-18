import { useState, useEffect } from 'react';
import { auth } from './firebase';
import { onAuthStateChanged, signOut, User } from 'firebase/auth';
import { UserAuth } from './types/service';
import { Navbar } from './components/Navbar';
import { LoginScreen } from './components/LoginScreen';
import { Dashboard } from './components/Dashboard';

export function App() {
  const [user, setUser] = useState<UserAuth | null>(null);
  const [isInitializing, setIsInitializing] = useState(true);
  const [isHardcodedModalOpen, setIsHardcodedModalOpen] = useState(false);

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (fbUser: User | null) => {
      if (fbUser) {
        setUser({
          uid: fbUser.uid,
          email: fbUser.email,
          isAdmin: true,
        });
      } else {
        setUser(null);
      }
      setIsInitializing(false);
    });

    return () => unsubscribe();
  }, []);

  const handleLogout = async () => {
    try {
      await signOut(auth);
    } catch (err) {
      console.error('Logout error:', err);
    }
  };

  if (isInitializing) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-[#faf7f2]">
        <div className="text-center space-y-3">
          <div className="w-12 h-12 border-4 border-emerald-800 border-t-transparent rounded-full animate-spin mx-auto" />
          <p className="text-xs font-bold text-slate-700">جاري التحقق من جلسة المسؤول...</p>
        </div>
      </div>
    );
  }

  if (!user) {
    return <LoginScreen />;
  }

  return (
    <div className="min-h-screen bg-[#faf7f2]">
      <Navbar
        user={user}
        onLogout={handleLogout}
        onOpenHardcodedModal={() => setIsHardcodedModalOpen(true)}
      />
      <main>
        <Dashboard
          isHardcodedModalOpen={isHardcodedModalOpen}
          onCloseHardcodedModal={() => setIsHardcodedModalOpen(false)}
        />
      </main>
    </div>
  );
}

export default App;
