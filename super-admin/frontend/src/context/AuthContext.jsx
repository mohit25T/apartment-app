import { createContext, useContext, useState, useEffect } from "react";

const AuthContext = createContext();

export const AuthProvider = ({ children }) => {
  const [token, setToken] = useState(
    localStorage.getItem("token") || null
  );

  // 🔐 login
  const login = (jwt) => {
    localStorage.setItem("token", jwt);
    window.__AUTH_TOKEN__ = jwt;
    setToken(jwt);
  };

  // 🔓 logout
  const logout = () => {
    localStorage.removeItem("token");
    window.__AUTH_TOKEN__ = null;
    setToken(null);
  };

  // 🔁 restore token on refresh
  useEffect(() => {
    if (token) {
      window.__AUTH_TOKEN__ = token;
    }
  }, [token]);

  return (
    <AuthContext.Provider value={{ token, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => useContext(AuthContext);
