-- lua/plugins/image.lua
return {
  "3rd/image.nvim",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
  },
  opts = {
    backend = "sixel", -- 根据终端调整：kitty / sixel / ueberzug
    integrations = {
      markdown = {
        enabled = false, -- 你已禁用 Markdown 渲染（避免卡顿）
        download_remote_images = true,
        only_render_image_at_cursor = true,
      },
      -- ⭐ 新增：启用 molten 集成
      molten = {
        enabled = true,
      },
    },
    -- ⭐ 调整尺寸：molten 输出图片通常需要更大显示
    max_width = 80, -- 单位：终端列数，可根据喜好调大
    max_height = 20, -- 单位：终端行数，建议至少 15
    max_width_window_percentage = math.huge, -- 不限制窗口比例
    max_height_window_percentage = math.huge,
    window_overlap_clear_enabled = true,
    window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
  },
}
