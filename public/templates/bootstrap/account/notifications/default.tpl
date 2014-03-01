<div class="row">
  <div class="col-lg-4">
    <div class="panel panel-info">
      <div class="panel-heading">
        <i class="fa fa-gear fa-fw"></i> Notification Settings
      </div>
      <div class="panel-body">
        <form action="{$smarty.server.SCRIPT_NAME}" method="POST" role="form">
          <input type="hidden" name="page" value="{$smarty.request.page|escape}">
          <input type="hidden" name="action" value="{$smarty.request.action|escape}">
          <input type="hidden" name="do" value="save">
          <input type="hidden" name="ctoken" value="{$CTOKEN|escape|default:""}" />
          <table class="table borderless">
            <tr>
              <td>
                <label>IDLE Worker</label>
              </td>
              <td>
                <input type="hidden" name="data[idle_worker]" value="0" />
                <input type="checkbox" data-size="small" name="data[idle_worker]" id="idle_worker" value="1"{nocache}{if $SETTINGS['idle_worker']|default:"0" == 1}checked{/if}{/nocache} />
                <script>
                  $("[id='idle_worker']").bootstrapSwitch();
                </script>
              </td>
            </tr>
      {if $DISABLE_BLOCKNOTIFICATIONS|default:"" != 1}
            <tr>
              <td>
                <label>New Blocks</label>
              </td>
              <td>
                <input type="hidden" name="data[new_block]" value="0" />
                <input type="checkbox" data-size="small" name="data[new_block]" id="new_block" value="1"{nocache}{if $SETTINGS['new_block']|default:"0" == 1}checked{/if}{/nocache} />
                <script>
                $("[id='new_block']").bootstrapSwitch();
                </script>
              </td>
            </tr>
      {/if}
            <tr>
              <td>
                <label>Payout</label>
              </td>
              <td>
                <input type="hidden" name="data[payout]" value="0" />
                <input type="checkbox" data-size="small" name="data[payout]" id="payout" value="1"{nocache}{if $SETTINGS['payout']|default:"0" == 1}checked{/if}{/nocache} />
                <script>
                $("[id='payout']").bootstrapSwitch();
                </script>
              </td>
            </tr>
            <tr>
              <td>
                <label>Successful Login</label>
              </td>
              <td>
                <input type="hidden" name="data[success_login]" value="0" />
                <input type="checkbox" data-size="small"  name="data[success_login]" id="success_login" value="1"{nocache}{if $SETTINGS['success_login']|default:"0" == 1}checked{/if}{/nocache} />
                <script>
                $("[id='success_login']").bootstrapSwitch();
                </script>
              </td>
            </tr>
          </table>
          </div>
          <div class="panel-footer">
          <input type="submit" value="Update" class="btn btn-success">
        </form>
      </div>
    </div>
  </div>

  <div class="col-lg-8">
    <div class="panel panel-info">
      <div class="panel-heading">
        <i class="fa fa-clock-o fa-fw"></i> Notification History
      </div>
      <div class="panel-body no-padding">
        <div class="table-responsive">
          <table class="table table-striped table-bordered table-hover">
            <thead>
              <tr>
                <th>ID</th>
                <th>Time</th>
                <th>Type</th>
                <th>Active</th>
              </tr>
            </thead>
            <tbody style="font-size:12px;">
{section notification $NOTIFICATIONS}
              <tr>
                <td>{$NOTIFICATIONS[notification].id}</td>
                <td>{$NOTIFICATIONS[notification].time}</td>
                <td>
{if $NOTIFICATIONS[notification].type == new_block}New Block
{else if $NOTIFICATIONS[notification].type == payout}Payout
{else if $NOTIFICATIONS[notification].type == idle_worker}IDLE Worker
{else if $NOTIFICATIONS[notification].type == success_login}Successful Login
{/if}
                </td>
                <td>
                 <i class="fa fa-{if $NOTIFICATIONS[notification].active}check{else}times{/if} fa-fw"></i>
                </td>
              </tr>
{/section}
            <tbody>
          </table>
        </div>
      </div>
    </div>
  </div>
</div>