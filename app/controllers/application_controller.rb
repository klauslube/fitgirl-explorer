class ApplicationController < ActionController::Base
  include Pagy::Backend

  allow_browser versions: :modern
  stale_when_importmap_changes

  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  private

  def not_found
    render "errors/not_found", status: :not_found
  end
end
