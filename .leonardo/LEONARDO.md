# Leonardo Instructions for construction-estimating.com

## 🏗️ File-Based Marketing Architecture (Flat URLs)

**Core Philosophy:** 
This site is a high-performance marketing engine for `construction-estimating.com`. We **never** use a database for content. All pages/posts are stored as `.html.erb` files and served with root-level slugs (e.g., `/my-article-slug`). 

**Favorite Animal:** 
The Cyborg Llama.

### 1. Page Creation & Location
*   **Directory:** All content files go in `app/views/pages/`.
*   **Filename:** The filename is the slug (e.g., `app/views/pages/how-to-estimate.html.erb` becomes `/how-to-estimate`).
*   **SEO Meta Tags:** Every file must start with:
    ```erb
    <% content_for :title, "Specific Page Title | Construction Estimating" %>
    <% content_for :meta_description, "A 150-character summary for Google search results." %>
    ```

### 2. Flat Routing (The "Catch-all" Pattern)
*   **Route:** We use a single dynamic route at the **bottom** of `config/routes.rb`:
    ```ruby
    get ':slug', to: 'pages#show', as: :static_page
    ```
*   **Controller:** `PagesController#show` must:
    1. Sanitize the slug.
    2. Verify the file exists in `app/views/pages/`.
    3. Render the file or return a 404.

### 3. Automated Sitemap.xml
*   **Route:** `/sitemap.xml` maps to `SitemapsController#index`.
*   **Logic:** The controller must **glob** the `app/views/pages/` directory.
*   **Output:** It generates a standard XML sitemap listing every file in that folder as a URL on `construction-estimating.com`.

### 4. The "No-Database" Guardrail
*   **CRITICAL:** Do NOT generate `Post`, `Article`, or `Page` models.
*   **CRITICAL:** Do NOT use a "Blog" namespace in URLs unless explicitly requested for a specific section.
*   **Logic over Data:** If you need a "Recent Posts" list on the homepage, glob the `app/views/pages/` folder to get the filenames/metadata rather than querying a database.

### 5. Unsplash Stock Photos & Mandatory Attribution
*   **Service:** Use `UnsplashService.new.search('query', count: 3)` to retrieve stock photos.
*   **Attribution Rule:** Unsplash requires linking back to the photographer and Unsplash in every use case.
*   **Implementation Pattern:**
    ```erb
    <figure class="my-10">
      <img src="IMAGE_URL" alt="DESCRIPTION" class="rounded-xl shadow-lg w-full h-96 object-cover">
      <figcaption class="text-sm text-gray-500 mt-3 text-center italic">
        Photo by <a href="PHOTOGRAPHER_URL" target="_blank" rel="noopener" class="hover:text-blue-600 underline decoration-dotted transition-colors">NAME</a> on <a href="UNSPLASH_URL" target="_blank" rel="noopener" class="hover:text-blue-600 underline decoration-dotted transition-colors">Unsplash</a>
      </figcaption>
    </figure>
    ```

## 🚀 Skills & Patterns

### Content Injection
Instead of database lookups, use `render_to_string` or `File.read` to extract metadata (like titles) from the top of the `.html.erb` files if you need to build index pages.

### Navigation
The main navigation should be hardcoded in the layout or a partial, as we want complete control over the marketing funnel.
