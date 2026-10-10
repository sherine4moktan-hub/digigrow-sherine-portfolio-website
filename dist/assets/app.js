(() => {
  const data = window.DIGIGROW;
  const page = document.body.dataset.page || "home";
  const bookingHref = data.bookingUrl || "/contact#consultation-form";
  const icon = (name, size = 20) => {
    const paths = {
      arrow: '<path d="M5 12h14M13 6l6 6-6 6"/>',
      chevron: '<path d="m9 18 6-6-6-6"/>',
      check: '<path d="m5 12 4 4L19 6"/>',
      spark: '<path d="m12 3-1.5 5.5L5 10l5.5 1.5L12 17l1.5-5.5L19 10l-5.5-1.5L12 3Z"/><path d="m5 3-.5 2L3 5.5 5 6l.5 2L6 6l2-.5L6 5l-.5-2H5Z"/>',
      menu: '<path d="M4 7h16M4 12h16M4 17h16"/>',
      close: '<path d="m6 6 12 12M18 6 6 18"/>',
      external: '<path d="M15 4h5v5M10 14 20 4"/><path d="M18 13v6a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V7a1 1 0 0 1 1-1h6"/>'
    };
    return `<svg aria-hidden="true" width="${size}" height="${size}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">${paths[name] || paths.arrow}</svg>`;
  };

  const nav = [
    ["home", "/", "Home"], ["about", "/about", "About Me"], ["services", "/services", "Services"],
    ["blog", "/blog", "Blog"], ["contact", "/contact", "Contact"]
  ];

  const header = document.querySelector(".site-header");
  if (header) {
    header.innerHTML = `
      <div class="nav-shell container">
        <a class="brand-logo-link" href="/" aria-label="Digigrow Sherine, home">
          <img class="brand-logo" src="/assets/digigrow-sherine-logo-classic-v6-trimmed.png" width="2146" height="601" alt="Digigrow Sherine">
        </a>
        <nav class="desktop-nav" aria-label="Primary navigation">
          ${nav.map(([id, href, label]) => `<a href="${href}"${id === page || (page === "article" && id === "blog") ? ' aria-current="page"' : ""}>${label}</a>`).join("")}
        </nav>
        <a class="button button-small header-cta" href="${bookingHref}">${data.bookingUrl ? icon("external", 17) : ""}<span>Book a Free Consultation Call</span></a>
        <button class="menu-toggle" type="button" aria-expanded="false" aria-controls="mobile-navigation" aria-label="Open navigation menu">
          <span class="menu-open">${icon("menu", 24)}</span><span class="menu-close">${icon("close", 24)}</span>
        </button>
      </div>
      <div class="mobile-panel" id="mobile-navigation">
        <nav aria-label="Mobile navigation">
          ${nav.map(([id, href, label]) => `<a href="${href}"${id === page || (page === "article" && id === "blog") ? ' aria-current="page"' : ""}>${label}<span>${icon("arrow", 18)}</span></a>`).join("")}
          <a class="button" href="${bookingHref}"><span>Book a Free Consultation Call</span>${icon("arrow", 18)}</a>
        </nav>
      </div>`;

    const menu = header.querySelector(".menu-toggle");
    const panel = header.querySelector(".mobile-panel");
    const closeMenu = () => {
      menu.setAttribute("aria-expanded", "false");
      menu.setAttribute("aria-label", "Open navigation menu");
      panel.classList.remove("is-open");
      document.body.classList.remove("menu-is-open");
    };
    menu.addEventListener("click", () => {
      const open = menu.getAttribute("aria-expanded") !== "true";
      menu.setAttribute("aria-expanded", String(open));
      menu.setAttribute("aria-label", open ? "Close navigation menu" : "Open navigation menu");
      panel.classList.toggle("is-open", open);
      document.body.classList.toggle("menu-is-open", open);
      if (open) panel.querySelector("a").focus();
    });
    document.addEventListener("keydown", (event) => { if (event.key === "Escape") { closeMenu(); menu.focus(); } });
    window.addEventListener("resize", () => { if (window.innerWidth > 880) closeMenu(); });
  }

  document.querySelectorAll("[data-booking-link]").forEach((link) => {
    link.href = bookingHref;
    if (data.bookingUrl) {
      link.target = "_blank";
      link.rel = "noopener noreferrer";
      link.setAttribute("aria-label", `${link.textContent.trim()} (opens scheduling page in a new tab)`);
    } else if (location.pathname.replace(/\/$/, "") === "/contact") {
      link.addEventListener("click", (event) => {
        const formTarget = document.getElementById("consultation-form");
        if (!formTarget) return;
        event.preventDefault();
        history.replaceState(null, "", "#consultation-form");
        const formTop = formTarget.getBoundingClientRect().top + window.scrollY - 94;
        const previousScrollBehavior = document.documentElement.style.scrollBehavior;
        document.documentElement.style.scrollBehavior = "auto";
        window.scrollTo({ top: formTop, behavior: "auto" });
        requestAnimationFrame(() => { document.documentElement.style.scrollBehavior = previousScrollBehavior; });
      });
    }
  });

  const footer = document.querySelector(".site-footer");
  if (footer) {
    const year = new Date().getFullYear();
    footer.innerHTML = `
      <div class="container footer-grid">
        <div class="footer-brand">
          <a class="brand-logo-link footer-logo-link" href="/" aria-label="Digigrow Sherine, home"><img class="brand-logo footer-logo" src="/assets/digigrow-sherine-logo-classic-v6-trimmed.png" width="2146" height="601" alt="Digigrow Sherine"></a>
          <p><strong>Sherine Moktan</strong><br>AI Marketing Expert</p>
          <p>Helping small and medium businesses grow online with AI-Powered Digital Marketing.</p>
        </div>
        <div><h2>Explore</h2><ul>${nav.map(([, href, label]) => `<li><a href="${href}">${label}</a></li>`).join("")}</ul></div>
        <div><h2>Services</h2><ul>${data.services.slice(0, 4).map((service) => `<li><a href="/services#${service.id}">${service.title}</a></li>`).join("")}</ul></div>
        <div class="footer-action"><span class="eyebrow eyebrow-light">Ready to grow?</span><h2>Let’s talk about your business.</h2><a class="text-link text-link-light" href="${bookingHref}">Book a Free Consultation Call ${icon("arrow", 18)}</a></div>
      </div>
      <div class="container footer-base"><p>© ${year} Digigrow Sherine. All rights reserved.</p><p>AI Marketing Expert · Digital Marketing for Small Businesses</p></div>`;
  }

  document.querySelectorAll(".faq-item").forEach((item) => {
    const button = item.querySelector(".faq-question");
    const answer = item.querySelector(".faq-answer");
    button.addEventListener("click", () => {
      const expanded = button.getAttribute("aria-expanded") === "true";
      document.querySelectorAll(".faq-question[aria-expanded='true']").forEach((openButton) => {
        if (openButton !== button) {
          openButton.setAttribute("aria-expanded", "false");
          openButton.closest(".faq-item").querySelector(".faq-answer").hidden = true;
        }
      });
      button.setAttribute("aria-expanded", String(!expanded));
      answer.hidden = expanded;
    });
  });

  const reveals = document.querySelectorAll("[data-reveal]");
  if ("IntersectionObserver" in window && !window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
    document.documentElement.classList.add("reveal-ready");
    const observer = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) { entry.target.classList.add("is-visible"); observer.unobserve(entry.target); }
      });
    }, { rootMargin: "0px 0px -8%", threshold: 0.08 });
    reveals.forEach((element, index) => {
      element.style.setProperty("--reveal-delay", `${Math.min(index % 5, 4) * 65}ms`);
      observer.observe(element);
    });
  }

  const blogGrid = document.querySelector("[data-blog-grid]");
  if (blogGrid) {
    const postImages = {
      "how-ai-can-help-small-business-marketing": "/assets/blog-ai-marketing-nepali-v2.jpg",
      "build-a-digital-marketing-plan": "/assets/blog-marketing-plan-nepali-v2.jpg",
      "turn-website-visitors-into-qualified-leads": "/assets/blog-qualified-leads-nepali-v2.jpg"
    };
    const search = document.querySelector("[data-blog-search]");
    const filters = [...document.querySelectorAll("[data-category]")];
    const empty = document.querySelector("[data-blog-empty]");
    let category = "All";
    const render = () => {
      const query = search.value.trim().toLowerCase();
      const matches = data.posts.filter((post) => (category === "All" || post.category === category) && `${post.title} ${post.excerpt} ${post.category}`.toLowerCase().includes(query));
      blogGrid.innerHTML = matches.map((post, index) => `
        <article class="blog-card" style="--card-index:${index}">
          <a class="blog-card-art" href="/blog/${post.slug}" aria-label="Read ${post.title}"><img src="${postImages[post.slug]}" alt="" loading="lazy"><span class="blog-card-number">${String(index + 1).padStart(2, "0")}</span></a>
          <div class="blog-card-content"><div class="blog-meta"><span>${post.category}</span><span>${post.readingTime}</span></div>
          <h2><a href="/blog/${post.slug}">${post.title}</a></h2><p>${post.excerpt}</p>
          <a class="text-link" href="/blog/${post.slug}">Read article ${icon("arrow", 17)}</a></div>
        </article>`).join("");
      empty.hidden = matches.length > 0;
      blogGrid.hidden = matches.length === 0;
    };
    filters.forEach((button) => button.addEventListener("click", () => {
      category = button.dataset.category;
      filters.forEach((item) => { item.classList.toggle("is-active", item === button); item.setAttribute("aria-pressed", String(item === button)); });
      render();
    }));
    search.addEventListener("input", render);
    render();
  }

  const form = document.querySelector("[data-consultation-form]");
  if (form) {
    const status = form.querySelector("[data-form-status]");
    const submit = form.querySelector("button[type='submit']");
    const showStatus = (message, type) => { status.textContent = message; status.className = `form-status ${type}`; status.hidden = false; status.focus(); };
    form.addEventListener("submit", async (event) => {
      event.preventDefault();
      status.hidden = true;
      [...form.querySelectorAll("[aria-invalid='true']")].forEach((field) => field.removeAttribute("aria-invalid"));
      if (!form.checkValidity()) {
        const invalid = form.querySelector(":invalid");
        invalid.setAttribute("aria-invalid", "true");
        invalid.focus();
        showStatus("Please complete the required fields and use a valid email address.", "error");
        return;
      }
      if (!data.formEndpoint) {
        showStatus("This form is ready, but online delivery has not been connected yet. Sherine needs to add a secure form endpoint before submissions can be sent.", "notice");
        return;
      }
      submit.disabled = true;
      submit.classList.add("is-loading");
      submit.querySelector("span").textContent = "Sending request…";
      try {
        const payload = Object.fromEntries(new FormData(form).entries());
        const response = await fetch(data.formEndpoint, { method: "POST", headers: { "Content-Type": "application/json", "Accept": "application/json" }, body: JSON.stringify(payload) });
        const result = await response.json().catch(() => ({}));
        if (!response.ok || result.success === false || result.success === "false") throw new Error(result.message || "Submission failed");
        form.reset();
        showStatus("Successfully submitted. Thank you for your consultation request. I’ll contact you to arrange a suitable time.", "success");
      } catch {
        showStatus("Your request could not be sent. Please check your connection and try again. If the problem continues, please return later.", "error");
      } finally {
        submit.disabled = false;
        submit.classList.remove("is-loading");
        submit.querySelector("span").textContent = "Request My Free Consultation";
      }
    });
  }
})();
