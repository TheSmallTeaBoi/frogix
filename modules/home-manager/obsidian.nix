{ config, ... }:

with config.lib.stylix.colors.withHashtag;

{
  home.file.obsidian-stylix-css = {
    enable = true;
    # THIS VALUE NEEDS TO CHANGE TO YOUR VAULT (relative to your home dir)
    target = "Data/Personal/obsidian/.obsidian/snippets/obsidian-stylix-css.css";
    text =
      #css
      "
        :root {
           --color-red: ${red};
           --color-orange: ${orange};
           --color-yellow: ${yellow};
           --color-green: ${green};
           --color-cyan: ${cyan};
           --color-blue: ${blue};
           --color-purple: ${magenta};
           --color-pink: ${magenta};

           --bold-color: ${red};
           --italic-color: ${magenta};
           --text-normal: ${base05};
           --text-muted: ${base04};
           --text-selection: ${blue};
           --text-highlight-bg: ${base00};
        }

        .theme-dark {
          --background-primary: ${base00};
          --background-secondary: ${base01};

          --background-modifier-cover: rgba(${base01-rgb-r},${base01-rgb-g},${base01-rgb-b}, 0.8); /*Obsidian Title Bar Bg*/
          --background-primary: ${base00}; /*Note background*/
          --background-primary-alt: ${base01}; /*Note Title background active*/
          --background-secondary: ${base01}; /*Sidebar background*/
          --background-secondary-alt: ${base00}; /*Sidebar Title background*/
          
          --background-modifier-border: ${base04}; /*Border outline of quotes, tables, line breaks*/
          
          --text-normal: ${base05}; /*Text body of note*/
          --text-muted: ${base04}; /*Text darker for sidebar, toggles, inactive, tags, etc*/
          --text-accent: ${blue}; /*Links*/
          --text-accent-hover: ${cyan}; /*Links hover*/
          --text-faint: ${base04}; /*Link brackets color & Gutter Numbers*/

          --text-highlight-bg: rgba(${base0E-rgb-r},${base0E-rgb-g},${base0E-rgb-b}, 0.4); /*Search Matches*/
          --text-highlight-bg-active: rgba(${base0A-rgb-r},${base0A-rgb-g},${base0A-rgb-b}, 0.4); /*Active Search Match (Preview Mode)*/
          --text-selection: rgba(${base0D-rgb-r},${base0D-rgb-g},${base0D-rgb-b}, 0.99); /*Text Selections*/

          --interactive-normal: ${base01}; /*Button Color*/
          --interactive-hover: ${base00}; /*Button Hovered Color*/
          --interactive-accent: ${magenta}; /*Workspace Note Title Underline*/
          --interactive-accent-hover: ${green}; /*Menu Button Hover*/
          
          --scrollbar-bg: rgba(${base00-rgb-r},${base00-rgb-g},${base00-rgb-b}, 0.05); /*Scrollbar Gutter Background*/
          --scrollbar-thumb-bg: rgba(${base0D-rgb-r},${base0D-rgb-g},${base0D-rgb-b}, 0.1); /*Scrollbar Color*/
          --scrollbar-active-thumb-bg: rgba(${base09-rgb-r},${base09-rgb-g},${base09-rgb-b}, 0.1); /*Scrollbar Color*/
        }
    ";
  };
}
