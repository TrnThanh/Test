import os
import re
import sys

if sys.stdout.encoding and sys.stdout.encoding.lower() != 'utf-8':
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

from playwright.sync_api import sync_playwright

def extract_mermaid(markdown_file):
    with open(markdown_file, "r", encoding="utf-8") as f:
        content = f.read()
    match = re.search(r"```mermaid\s*\n(.*?)\n```", content, re.DOTALL)
    if not match:
        raise ValueError(f"Không tìm thấy khối mermaid trong {markdown_file}")
    return match.group(1)

def render_diagrams():
    docs_dir = os.path.abspath("docs")
    erd_mermaid = extract_mermaid(os.path.join(docs_dir, "database.md"))
    class_mermaid = extract_mermaid(os.path.join(docs_dir, "class-diagram.md"))

    diagrams = [
        ("ERD", erd_mermaid, "erd-diagram.svg", "erd-diagram.png"),
        ("Class Diagram", class_mermaid, "class-diagram.svg", "class-diagram.png"),
    ]

    base_html = """<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8" />
  <script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>
  <style>
    body {
      margin: 0;
      padding: 30px;
      background-color: #ffffff;
      display: inline-block;
    }
    #render-container {
      background: #ffffff;
      display: inline-block;
    }
  </style>
</head>
<body>
  <div id="render-container"></div>
  <script>
    mermaid.initialize({
      startOnLoad: false,
      theme: 'default',
      maxTextSize: 200000,
      er: { useMaxWidth: false },
      flowchart: { useMaxWidth: false }
    });
  </script>
</body>
</html>"""

    with sync_playwright() as p:
        browser = p.chromium.launch(channel="chrome", headless=True)
        # Use high resolution
        page = browser.new_page(device_scale_factor=2)
        page.set_content(base_html)
        page.wait_for_function('() => typeof window.mermaid !== "undefined"', timeout=15000)

        for idx, (name, code, svg_name, png_name) in enumerate(diagrams):
            print(f"Đang vẽ {name}...")
            svg_id = f"svg_diagram_{idx}"
            
            # Gọi trực tiếp mermaid.render
            render_res = page.evaluate("""async ([svgId, mermaidCode]) => {
                try {
                    const { svg } = await window.mermaid.render(svgId, mermaidCode);
                    const container = document.getElementById('render-container');
                    container.innerHTML = svg;
                    return { ok: true, svg: svg };
                } catch(e) {
                    return { ok: false, err: e.message || String(e) };
                }
            }""", [svg_id, code])

            if not render_res.get("ok"):
                raise RuntimeError(f"Lỗi vẽ {name}: {render_res.get('err')}")

            svg_content = render_res["svg"]
            svg_path = os.path.join(docs_dir, svg_name)
            with open(svg_path, "w", encoding="utf-8") as f:
                f.write(svg_content)
            print(f"  ✓ Đã lưu SVG: {svg_path} ({os.path.getsize(svg_path)} bytes)")

            # Chờ DOM layout ổn định
            page.wait_for_timeout(1000)

            # Chụp ảnh PNG chất lượng cao
            png_path = os.path.join(docs_dir, png_name)
            svg_element = page.locator("#render-container svg")
            png_bytes = svg_element.screenshot()
            with open(png_path, "wb") as f:
                f.write(png_bytes)
            print(f"  ✓ Đã lưu PNG: {png_path} ({os.path.getsize(png_path)} bytes)")

        browser.close()
    print("\n🎉 HOÀN THÀNH VẼ VÀ XUẤT TOÀN BỘ SƠ ĐỒ THÀNH CÔNG!")

if __name__ == "__main__":
    render_diagrams()
