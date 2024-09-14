# Tech radar

Based upon [AOE's technology radar](https://github.com/AOEpeople/aoe_technology_radar).

Bootstrap:

1. Run `npm install`.
1. Run `npm run build` to create the initial radar.<br/>
   This will also create a basic bootstrap of all required files, including `config.json` and `about.md` if they do not
   exist yet.

Customization:

1. Change the `about.md`, `config.json`, `custom.css` files accordingly.
1. Create a folder named as a date in the `radar` folder to create a new revision.
1. Add markdown files in there for each change. Follow the instructions of the base.

Serve:

1. Execute `docker compose up -d`.
1. Open your browser at <http://localhost:8080/techradar/>.
