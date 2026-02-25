# frozen_string_literal: true

require "spec_helper"

# Tests for NestedMenu issues reported in github.com/antiwork/gumroad/issues/2724.
#
# Three sub-bugs were reported after the _nested_menu.scss → Tailwind migration (PR #2068):
#   1. Color mismatch — the overlay-menu trigger button had a transparent background
#      instead of the "filled" background that matches the search bar.
#   2. Close button removed — the backdrop close button was missing from the sidebar.
#   3. Code cleanup — redundant <div role="nav"> wrapper and the unused `menuTop` prop.

describe("Discover - Nested Menu (issue #2724)", :js, type: :feature) do
  let(:discover_host) { UrlService.discover_domain_with_protocol }

  # ---------------------------------------------------------------------------
  # Desktop (menubar) view
  # ---------------------------------------------------------------------------
  context "on desktop" do
    it "renders the category navigation inside a semantic nav element" do
      visit discover_url(host: discover_host)

      expect(page).to have_css("nav .nested-menu [role='menubar']")
    end

    it "does not use an invalid div[role='nav'] wrapper" do
      visit discover_url(host: discover_host)

      expect(page).not_to have_css("div[role='nav']")
    end
  end

  # ---------------------------------------------------------------------------
  # Mobile (overlay) view — uses mobile_view tag to switch Capybara driver
  # ---------------------------------------------------------------------------
  context "on mobile", :mobile_view do
    # Bug 1 — color mismatch
    describe "menu trigger button" do
      it "carries the 'filled' CSS class for background-color consistency with the search bar" do
        visit discover_url(host: discover_host)

        # The Button component adds the 'filled' class when color="filled" is passed,
        # which triggers @include bg-color(filled) in _button.scss.
        expect(page).to have_css("button.filled[aria-label='Categories']")
      end

      it "is not transparent (does not rely solely on inherited page background)" do
        visit discover_url(host: discover_host)

        # Ensure the element has the 'button' class AND the 'filled' class together,
        # meaning the design-system color prop was applied correctly.
        expect(page).to have_css("button.button.filled[aria-label='Categories']")
      end
    end

    # Bug 2 — close button
    describe "sidebar close button" do
      it "is present when the menu is open" do
        visit discover_url(host: discover_host)

        click_on "Categories"

        expect(page).to have_button("Close Menu")
      end

      it "closes the sidebar when clicked" do
        visit discover_url(host: discover_host)

        click_on "Categories"
        expect(page).to have_selector("[role='menuitem']", text: "All")

        click_on "Close Menu"
        expect(page).not_to have_selector("[role='menuitem']", text: "All")
      end

      it "is not visible when the menu is closed" do
        visit discover_url(host: discover_host)

        # The backdrop (and the close button inside it) is hidden via the HTML
        # `hidden` attribute when menuOpen is false.
        expect(page).not_to have_css(".backdrop:not([hidden]) button[aria-label='Close Menu']")
      end
    end

    # Bug 3 — code cleanup
    describe "redundant code removed" do
      it "wraps the menu in a semantic <nav> element (not div[role='nav'])" do
        visit discover_url(host: discover_host)

        expect(page).to have_css("nav .nested-menu")
        expect(page).not_to have_css("div[role='nav']")
      end

      it "does not apply an inline top style to the backdrop (menuTop prop removed)" do
        visit discover_url(host: discover_host)

        click_on "Categories"

        backdrop = find(".backdrop")
        # The SCSS already handles top: 0 via position: fixed; top: 0.
        # The menuTop="0px" inline style was redundant and should be gone.
        expect(backdrop["style"].to_s).not_to match(/\btop\s*:/)
      end
    end
  end
end
