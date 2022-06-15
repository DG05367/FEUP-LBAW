@foreach($posts as $post)
                <div style="margin-top: 10px; border: 1px solid black; padding-left: 10px;
                padding-top: 4px; padding-bottom: 4px">
                    <div style="display: flex">
                        <div>{{ $post->date }}</div>    
                        <div style="margin-left: 10px; margin-right: 10px">·</div>
                        <img src='https://upload.wikimedia.org/wikipedia/commons/thumb/f/fe/Sort_up_font_awesome.svg/768px-Sort_up_font_awesome.svg.png'
                        width='24' />
                        <div>{{ $post->votes }}</div>
                        <div style="margin-left: 10px; margin-right: 10px">·</div>
                        <div>Comments: {{ count($post->comments) }}</div>
                        <div style="margin-left: 10px; margin-right: 10px">·</div>
                        <div>Tag: <a href="/tag/{{ $post->tags->tag_id }}">{{ $post->tags->name }}</a></div> 
                    </div>
                    <div style="font-size: 22px; font-weight: bold">{{ $post->title }}</div>
                    <div>{{ strlen($post->description) > 200 ? substr($post->description,0,200)."..." : $post->description }}</div>
                </div>
            @endforeach