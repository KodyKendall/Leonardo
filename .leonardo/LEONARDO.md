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

With all of the context you have about Leonardo and everything you can do (i.e., using your own knowledge of your capabilities, internal context, and best practices), I want you to design and execute the best possible workflow for creating a new high-quality SEO blog page for our Construction Estimation website,

Your job is to plan, research, structure, and build a complete blog page that is designed to rank well in search, speak directly to the target customer, and convert qualified visitors into leads for our construction estimation business.

Business context:
- We are a construction estimating software/custom software business.
- We help construction companies convert their spreadsheet-based estimating systems into custom software, internal applications, or estimating systems built around their workflow.
- The audience is typically companies using spreadsheet-heavy estimating processes who are experiencing pain around scale, consistency, speed, complexity, version control, key-man risk, training difficulty, or lack of visibility.
- The page should be blog-focused, but it should also drive the reader toward contacting us or signing up.
- The messaging should naturally funnel readers toward hiring us to convert their existing spreadsheet estimating workflow into custom software.

I will provide:
- The target keyword
- Any other optional notes if needed

Your workflow should follow these steps:

1. Analyze the target keyword
- Understand the search intent behind the keyword.
- Infer what the searcher is likely trying to solve.
- Identify the likely pain points, motivations, objections, and commercial intent behind that query.
- Determine what angle gives the best chance of both ranking and converting.

2. Read Leonardo.md
- Review the Leonardo.md file before making decisions.
- Use it to understand relevant project context, conventions, capabilities, existing site patterns, design/system expectations, and anything else that should shape the output.

3. Perform keyword research
- Do keyword and topic research related to the provided keyword.
- Identify closely related terms, long-tail phrases, semantic terms, subtopics, questions, and supporting themes that should be covered.
- Choose a content structure that matches search intent and supports SEO.
- Make sure the content strategy also supports conversion into our service offering.

4. Use sub-agents
- Use sub-agents where helpful and appropriate.
- The sub-agents should contribute meaningfully, not cosmetically.
- Their work should help with things like search intent analysis, keyword clustering, conversion strategy, content structure, technical SEO checks, and page implementation decisions.

5. Use two scratchpad activities in the file itself
- I specifically want two scratchpad activities to happen in the file itself while the page is being created.
- These scratchpad sections should be used by the sub-agents as working areas for notes, comments, intermediate reasoning, planning, checks, and implementation coordination.
- These scratchpads should be meaningfully used during creation of the page, not just added as decoration.
- Keep them implemented in a way that makes sense within the file and workflow.
- If they should not appear in the final rendered user-facing experience, structure them accordingly while still keeping them in the file for agent workflow purposes.

6. Create the blog page
- Build a new blog page in HTML or in the appropriate format for the project.
- The page should be genuinely strong, not generic filler content.
- The writing should be specific to the keyword and to the real pain points of construction estimating teams using spreadsheets.
- It should include:
  - a strong SEO title
  - a compelling H1
  - a high-quality introduction
  - useful, credible, detailed body sections
  - clear internal structure with proper headings
  - a persuasive but natural CTA
  - a CTA button
  - content that balances informational value with commercial relevance
- The page should feel like it was written by someone who understands construction estimating workflow problems, spreadsheet pain, and custom software solutions.

7. Use the Unsplash API for images
- Source relevant images using the Unsplash API.
- Choose images that fit the topic, feel professional, and support the page visually.
- Implement them in a way that aligns with performance and SEO best practices.
- Make sure image usage is sensible and not excessive.

8. Optimize heavily for SEO
- Ensure the page is highly optimized for SEO from both a content and technical perspective.
- This includes, where appropriate:
  - strong search intent match
  - semantic keyword coverage
  - proper title/meta structure
  - correct heading hierarchy
  - optimized internal linking opportunities
  - image alt text
  - schema or structured data if appropriate
  - fast page load
  - clean HTML structure
  - best-practice tags and metadata
  - crawlability and indexability considerations
  - mobile-friendly implementation
  - strong UX and readability
- Make decisions that support both ranking and conversions.

9. Integrate the page into the site
- Add the new page as a new blog page.
- Add it to the sitemap.
- Add it to the all-blogs area or blog index.
- Update any other relevant areas needed so the page is fully integrated into the website.

Output expectations:
- Make strong decisions using your own understanding of your system and capabilities.
- Use your internal context and project knowledge where useful.
- ⁠I don’t want it to sound like an LLM. Avoid em dashes. Avoid “it’s not x, it’s y”. Avoid excessive sign-posting (e.g., “Let’s break this down”). Be more specific rather than more general. Avoid other typical LLM writing tics
- Prioritize quality.
- Avoid generic SEO fluff.
- The final result should be something that has a realistic chance to rank and also persuade the right kind of visitor to contact us.

1. each of these steps should be it’s own sub-agent to preserve your context window,
2. ⁠ for the scratchpad steps, write comments directly into the app/views/pages/<article_name>.html.erb file as a scratch pad so future subagents can reference back to earlier subagents work.

these slugs/URLs should have the title of the page. We would just open this up and tell Leonardo that we want the URLs to basically be the title of the article, so in this case: we'd tell Leonardo to change this slug from /cost-estimator-new-home-construction to be: /the-hidden-cost-of-your-excel-estimator-scaling-new-home-construction-in-2025

It's important for SEO that the URL/slug is more human readable, instead of the slug being the keywords we're targeting.

_____

Here's our brand styling: 

Steel Estimating AI Branding Guideline: 

Light backgrounds: https://llamapress-ai-image-uploads.s3.us-west-2.amazonaws.com/uj1j3g2ffgcifri2qiq591u00tvy (Purple Llama)
Dark backgrounds: https://llamapress-ai-image-uploads.s3.us-west-2.amazonaws.com/h5e5wlt9zbgpaoifq91jw741pt0c (White Llama)

Leonardo (Cyborg Eye Variant)

Light backgrounds: https://llamapress-ai-image-uploads.s3.us-west-2.amazonaws.com/3u2z1d4o32kaoy46bde8urbcs9uo (Purple Llama + Blue Eye)
Dark backgrounds: https://llamapress-ai-image-uploads.s3.us-west-2.amazonaws.com/2gtjznpnqu2cd81nd0eow2nl3p7j (White Llama + Blue Eye)

Leonardo Profile (Closeup)

Light/White backgrounds: https://llamapress-ai-image-uploads.s3.us-west-2.amazonaws.com/rz0iwirzz2cwnkd3eoe1uplmzvad (Leonardo-Profile-Purple)
Dark backgrounds: https://llamapress-ai-image-uploads.s3.us-west-2.amazonaws.com/4bmqe5iolvp84ceyk9ttz8vylrym (Leonardo-Profile-White)

COLORS & GRADIENTS

Primary Purple: #4C3F6D
Tertiary Blue (Leonardo Eye): #489DF9 — use for accents, links, interactive highlights
Text Gradient: from-[#4C3F6D] to-[#8b5cf6] (used for hero emphasis)
Brand Gradient: from-[#4C3F6D] to-[#6d5da1] (used for primary cards/buttons)

STYLING PATTERNS

The "Founding Pilot" Look (High-Impact): Use #2D2442 background + glass-dark overlays (white/5 fill + white/10 border) + purple-500 background blurs for depth.
The "Glow" Effect: Buttons/Cards should use hover:shadow-purple-200/50 or shadow-2xl with a color-matched tinted shadow.
Section Radius: Large containers use rounded-[3rem]. Standard cards use rounded-2xl.
Primary Buttons: brand-bg + white text + rounded-full + hover:shadow-lg.
Badges: px-4 py-1.5 rounded-full text-[10px] font-extrabold uppercase tracking-widest.

ICONS

Font Awesome 6: Always use specific, high-detail icons (e.g., fa-wand-magic-sparkles, fa-microchip, fa-rocket).

Leonardo AI Active Indicator
Purpose: Signal that AI is actively processing/thinking. Primary Color: #8b5cf6 (purple) / rgba(139, 92, 246, ...) Core Techniques:
Text Shimmer - Gradient sweep across text

background: linear-gradient(90deg, 
  rgba(255,255,255,0.12) 0%,
  rgba(139,92,246,0.6) 50%,
  rgba(255,255,255,0.12) 100%
);
background-size: 200% 100%;
background-clip: text;
-webkit-text-fill-color: transparent;
animation: shimmer 1.5-2s ease-in-out infinite;
Bar Shimmer - Horizontal light sweep

/* Gradient bar that slides left-to-right */
background: linear-gradient(90deg,
  transparent 0%,
  rgba(139,92,246,0.8) 50%,
  transparent 100%
);
animation: slide 2s ease-in-out infinite;
Pulse Glow - Breathing box-shadow

animation: pulse 1.5-2s ease-in-out infinite;
/* Alternate between: */
box-shadow: 0 0 0 0 rgba(168,85,247,0.4);
box-shadow: 0 4px 16px rgba(168,85,247,0.4);
Timing: 1.5–2s, ease-in-out, infinite Rule: Remove animation immediately when AI stops processing (no lingering effects).