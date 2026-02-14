import { useState } from "react";
import Sidebar from "./Sidebar";
import Header from "./Header";
import Footer from "./Footer";

const AppLayout = ({ children }) => {
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);

  return (
    <div className="min-h-screen bg-gray-100">
      {/* Sidebar (controlled) */}
      <Sidebar open={isSidebarOpen} setOpen={setIsSidebarOpen} />

      {/* Main Layout */}
      <div className="flex flex-col min-h-screen">
        <Header
          isSidebarOpen={isSidebarOpen}
          setIsSidebarOpen={setIsSidebarOpen}
        />

        <main className="p-6 flex-1">{children}</main>
        <Footer />
      </div>
    </div>
  );
};

export default AppLayout;
