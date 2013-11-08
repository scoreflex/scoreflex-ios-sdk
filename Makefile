.PHONY: appledoc
appledoc:
	mkdir -p appledoc && appledoc  --project-name Scoreflex --project-company Yakaz --company-id com.scoreflex --output appledoc --keep-intermediate-files Scoreflex
