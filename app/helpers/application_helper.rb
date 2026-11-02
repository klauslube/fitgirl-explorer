module ApplicationHelper
  include Pagy::Frontend

  GB = 1024**3

  def format_size(bytes)
    return unless bytes
    return "#{(bytes.to_f / 1024**2).round} MB" if bytes < GB
    "#{(bytes.to_f / GB).round(1)} GB"
  end

  def repack_size_label(game)
    return unless game.repack_size_min_bytes
    if game.repack_size_range?
      "#{format_size(game.repack_size_min_bytes)} – #{format_size(game.repack_size_max_bytes)}"
    else
      format_size(game.repack_size_min_bytes)
    end
  end

  def comments_label(count)
    number_with_delimiter(count)
  end

  # Catalog URL keeping the current filters but changing some params (and resetting the page).
  def catalog_path_with(params_hash, **changes)
    base = params_hash.except(:page, "page", "controller", "action").to_h.symbolize_keys.merge(changes)
    games_path(base.compact_blank)
  end

  def tag_link(tag)
    link_to tag.name, games_path(tag_ids: [ tag.id ]),
      class: "rounded bg-white/5 px-2 py-0.5 text-xs text-slate-300 hover:bg-sky-400/20 hover:text-sky-200"
  end

  def sort_options
    [ [ "Most commented", "comments_desc" ], [ "Least commented", "comments_asc" ], [ "Newest", "newest" ],
      [ "Oldest", "oldest" ], [ "Name A–Z", "name" ], [ "Largest repack", "size_desc" ], [ "Smallest repack", "size_asc" ] ]
  end
end
