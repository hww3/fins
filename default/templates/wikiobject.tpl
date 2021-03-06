<html>
<head>
  {include:header.tpl}
   <title>electronic alchemy :: {title}</title>
</head>
<body>
{include:tagline.tpl}
   <div id="page-wrapper">
    <div id="page-content">
      {if:isblog:data->object_is_weblog}
      {else:isblog}
   <h3>{title}</h3>
   Created by {author_username}. Last updated by {editor_username}, 
{when}. Version #{version}.
     {endif:isblog}
{if:loggedin:data->user}<div class="snip-buttons"> [ <a href="/exec/edit/{obj}">edit</a> ] </div> 
{endif:loggedin}
<div class="flash-message">{!flash:msg}</div>
   <div class="snip-wrapper">
      <div class="snip-content">
   {include:attachmentform.tpl}
         {content}
<p/>
{if:weblog:data->object_is_weblog}
{else:weblog}
         <b>{if:comments:data->numcomments}
                 <a href="/comments/{obj}">{numcomments} comments</a></b>
            {else:comments}
                 No comments 
            {endif:comments}
 | <a href="/exec/comments/{obj}">Post a Comment</a>
         <p/>
{endif:weblog}
         </div>
      </div>
      </div>
      </div>
         <div id="page-portlet-1-wrapper">
          <div id="page-portlet-1">
         {!snip:template/portlet-1}
         </div>
         </div>
         
</div>

<div id="page-bottom"><a href="/app/contact+info">contact info</a> | Copyright 1995-2005 Bill Welliver</div>
</body>
</html>
