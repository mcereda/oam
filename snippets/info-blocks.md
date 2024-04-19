<!-- markdownlint-disable-file MD041 -->

The idea here is to mimic Confluence's Info panel.

This only worked for Azure Devops' wikis.

<style>
  .info-block {
    margin: 1em 0;
    padding: 1em 1em 0;
  }
  .info-block header {
    font-weight: bold;
    margin-bottom: 0.5em;
  }
  .alert {
    background-color: rgba(255,0,0,0.0625);    /* red #FF0000 rgb(255,0,0) */
    border: solid tomato;                      /* tomato #FF6347 rgb(255,99,71) */
  }
  .info {
    background-color: rgba(0,191,255,0.0625);  /* deepSkyBlue #00BFFF rgb(0,191,255) */
    border: solid dodgerBlue;                  /* dodgerBlue #1E90FF rgb(30,144,255) */
  }
  .note {
    background-color: rgba(128,0,128,0.0625);  /* purple #800080 rgb(128,0,128) */
    border: solid mediumPurple;                /* mediumPurple #9370DB rgb(147,112,219) */
  }
  .tip {
    background-color: rgba(0,255,0,0.0625);    /* green #00FF00 rgb(0,255,0) */
    border: solid lightGreen;                  /* lightGreen #90EE90 rgb(144,238,144) */
  }
  .warning {
    background-color: rgba(255,255,0,0.0625);  /* yellow #FFFF00 rgb(255,255,0) */
    border: solid yellow;                      /* yellow #FFFF00 rgb(255,255,0) */
  }
</style>

<div class="info-block tip">
  <header>💡 Tip</header>

content

</div>

<div class="info-block info">
  <header>ⓘ Info</header>

content

</div>

<div class="info-block note">
  <header>🗒 Note</header>

content

</div>

<div class="info-block warning">
  <header>⚠ Warning</header>

content

</div>

<div class="info-block alert">
  <header>🛑 Alert</header>

content

</div>
