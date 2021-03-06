class ContentImagesController < ApplicationController
  before_filter :login_required

  def create
    @content_image = ContentImage.new(:file => params[:image],
                                      :user => current_user)

    if @content_image.save
      data = {
        :success => true,
        :html => render_to_string(:partial => "content_image",
                                  :locals => {
                                    :content_image => @content_image,
                                    :entry_type => params[:type]
                                  }),
        :url => @content_image.url(:large)
      }
    else
      data = {:success => false}
    end

    render(:partial => "shared/remotipart_response.js",
           :locals => { :data => data })
  end

  def destroy
    @content_image = ContentImage.find_by_id(params[:id])

    raise Goalie::NotFound if @content_image.blank?

    @content_image.delay.destroy

    if request.xhr?
      render :json => { :success => true }
    end
  end

end



