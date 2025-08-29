#!/usr/bin/env python3
"""
Simple HTTP Server for MyBus Admin Web Dashboard
تشغيل خادم بسيط لواجهة الويب الخاصة بإدارة MyBus
"""

import http.server
import socketserver
import webbrowser
import os
import sys
from pathlib import Path

# Configuration
PORT = 8090
HOST = 'localhost'

class MyHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    """Custom HTTP request handler with CORS support"""
    
    def end_headers(self):
        # Add CORS headers
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        super().end_headers()
    
    def do_OPTIONS(self):
        # Handle preflight requests
        self.send_response(200)
        self.end_headers()
    
    def log_message(self, format, *args):
        # Custom log format
        print(f"[{self.log_date_time_string()}] {format % args}")

def main():
    """Main function to start the server"""
    
    # Change to the web_admin directory
    web_admin_path = Path(__file__).parent
    os.chdir(web_admin_path)
    
    print("🚀 بدء تشغيل خادم MyBus Admin Dashboard...")
    print(f"📁 مجلد العمل: {web_admin_path}")
    print(f"🌐 العنوان: http://{HOST}:{PORT}")
    print("=" * 50)
    
    try:
        # Create server
        with socketserver.TCPServer((HOST, PORT), MyHTTPRequestHandler) as httpd:
            print(f"✅ الخادم يعمل على http://{HOST}:{PORT}")
            print("📱 لوحة تحكم MyBus Admin جاهزة!")
            print("\n🔑 بيانات تسجيل الدخول:")
            print("   📧 البريد الإلكتروني: admin@mybus.com")
            print("   🔒 كلمة المرور: admin123456")
            print("\n⚠️  للإيقاف: اضغط Ctrl+C")
            print("=" * 50)
            
            # Open browser automatically
            try:
                webbrowser.open(f'http://{HOST}:{PORT}')
                print("🌐 تم فتح المتصفح تلقائياً")
            except:
                print("⚠️  لم يتم فتح المتصفح تلقائياً، افتحه يدوياً")
            
            # Start serving
            httpd.serve_forever()
            
    except KeyboardInterrupt:
        print("\n\n🛑 تم إيقاف الخادم بواسطة المستخدم")
        print("👋 شكراً لاستخدام MyBus Admin Dashboard!")
        
    except OSError as e:
        if e.errno == 48:  # Address already in use
            print(f"❌ خطأ: المنفذ {PORT} مستخدم بالفعل")
            print("💡 جرب منفذ آخر أو أوقف الخدمة الأخرى")
        else:
            print(f"❌ خطأ في النظام: {e}")
        sys.exit(1)
        
    except Exception as e:
        print(f"❌ خطأ غير متوقع: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
