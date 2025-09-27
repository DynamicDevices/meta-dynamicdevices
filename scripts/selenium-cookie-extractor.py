#!/usr/bin/env python3
"""
Selenium-based Foundries.io Cookie Extractor
Fully automated browser login and cookie extraction
"""

import os
import sys
import time
import json
import requests
from pathlib import Path

try:
    from selenium import webdriver
    from selenium.webdriver.common.by import By
    from selenium.webdriver.support.ui import WebDriverWait
    from selenium.webdriver.support import expected_conditions as EC
    from selenium.webdriver.chrome.options import Options
    from selenium.common.exceptions import TimeoutException, WebDriverException
except ImportError:
    print("❌ Selenium not installed. Install with: pip3 install selenium")
    print("   Also need: sudo apt install chromium-chromedriver")
    sys.exit(1)

class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    NC = '\033[0m'

def print_status(msg):
    print(f"{Colors.GREEN}[INFO]{Colors.NC} {msg}")

def print_warning(msg):
    print(f"{Colors.YELLOW}[WARN]{Colors.NC} {msg}")

def print_error(msg):
    print(f"{Colors.RED}[ERROR]{Colors.NC} {msg}")

def print_header(msg):
    print(f"{Colors.BLUE}{msg}{Colors.NC}")

def test_cookie(cookie_value):
    """Test if cookie is valid"""
    try:
        headers = {'Cookie': f'osfogsid={cookie_value}'}
        response = requests.get(
            'https://api.foundries.io/projects/dynamic-devices/lmp/builds/',
            headers=headers,
            timeout=10
        )
        
        if response.status_code == 200 and response.text.startswith('{'):
            return True
        return False
    except:
        return False

def extract_cookie_selenium():
    """Extract cookie using Selenium automation"""
    print_header("🤖 Selenium Automated Cookie Extraction")
    print_header("========================================")
    
    # Setup Chrome options
    chrome_options = Options()
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")
    
    # Try to use existing user profile for saved credentials
    user_data_dir = os.path.expanduser("~/.config/google-chrome")
    if os.path.exists(user_data_dir):
        chrome_options.add_argument(f"--user-data-dir={user_data_dir}")
        chrome_options.add_argument("--profile-directory=Default")
    
    driver = None
    try:
        print_status("🌐 Starting Chrome browser...")
        
        # Try different driver paths
        driver_paths = [
            '/usr/bin/chromedriver',
            '/usr/local/bin/chromedriver',
            'chromedriver'
        ]
        
        driver = None
        for driver_path in driver_paths:
            try:
                if driver_path == 'chromedriver':
                    driver = webdriver.Chrome(options=chrome_options)
                else:
                    driver = webdriver.Chrome(executable_path=driver_path, options=chrome_options)
                break
            except WebDriverException:
                continue
        
        if not driver:
            print_error("❌ ChromeDriver not found. Install with: sudo apt install chromium-chromedriver")
            return None
        
        print_status("🔐 Navigating to Foundries.io...")
        driver.get("https://app.foundries.io/factories/dynamic-devices/")
        
        # Wait a bit for page to load
        time.sleep(3)
        
        # Check if we're already logged in
        current_url = driver.current_url
        if "login" not in current_url and "app.foundries.io" in current_url:
            print_status("✅ Already logged in!")
        else:
            print_status("🔑 Please log in manually in the browser window...")
            print_status("   Waiting up to 60 seconds for login completion...")
            
            # Wait for login completion (URL change away from login page)
            try:
                WebDriverWait(driver, 60).until(
                    lambda d: "login" not in d.current_url and "app.foundries.io" in d.current_url
                )
                print_status("✅ Login detected!")
            except TimeoutException:
                print_error("❌ Login timeout - please try again")
                return None
        
        # Extract cookies
        print_status("🍪 Extracting cookies...")
        cookies = driver.get_cookies()
        
        osfogsid_cookie = None
        for cookie in cookies:
            if cookie['name'] == 'osfogsid' and 'foundries.io' in cookie.get('domain', ''):
                osfogsid_cookie = cookie['value']
                break
        
        if osfogsid_cookie:
            print_status("✅ Cookie extracted!")
            
            # Test the cookie
            if test_cookie(osfogsid_cookie):
                print_status("✅ Cookie validated!")
                return osfogsid_cookie
            else:
                print_error("❌ Cookie validation failed")
                return None
        else:
            print_error("❌ osfogsid cookie not found")
            return None
            
    except Exception as e:
        print_error(f"❌ Browser automation failed: {e}")
        return None
    
    finally:
        if driver:
            driver.quit()

def main():
    script_dir = Path(__file__).parent
    project_root = script_dir.parent
    cookie_file = project_root / "foundries-cookie.local"
    
    print_header("🔐 Foundries.io Selenium Cookie Extractor")
    print_header("==========================================")
    
    # Try automated extraction
    cookie_value = extract_cookie_selenium()
    
    if cookie_value:
        # Save cookie
        with open(cookie_file, 'w') as f:
            f.write(f'FOUNDRIES_COOKIE="osfogsid={cookie_value}"\n')
        
        print_status(f"💾 Cookie saved to: {cookie_file}")
        print_status("🎉 Automated cookie extraction successful!")
        
        # Test with a build API call
        print_status("🧪 Testing cookie with API call...")
        try:
            headers = {'Cookie': f'osfogsid={cookie_value}'}
            response = requests.get(
                'https://api.foundries.io/projects/dynamic-devices/lmp/builds/',
                headers=headers,
                timeout=10
            )
            
            if response.status_code == 200:
                builds = response.json()
                if builds:
                    latest_build = builds[0]['build_id']
                    print_status(f"✅ API test successful! Latest build: {latest_build}")
                else:
                    print_status("✅ API test successful! (No builds found)")
            else:
                print_warning(f"⚠️ API test returned status: {response.status_code}")
        
        except Exception as e:
            print_warning(f"⚠️ API test failed: {e}")
        
        return True
    else:
        print_error("❌ Automated cookie extraction failed")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)

