.PHONY: serve
serve:
	cd docs && bundle exec jekyll serve --livereload

# This is needed if you're going to be running jekyll locally.
# You need to install ruby and ruby devel packages and will
# likely want to set the GEM_HOME before running this.
# See https://jekyllrb.com/docs/installation/ubuntu/
.PHONY: install-gems
install-gems:
	gem install bundler jekyll
