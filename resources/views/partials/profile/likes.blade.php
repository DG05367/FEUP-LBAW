<div>
    likes work

    @foreach($posts as $post)
    <div style="border: 1px solid black; margin-bottom: 10px" id={{ $post->post_id }}>
        <div style="display: flex">
            <div style="border: 1px solid red">
                <img src='https://www.seekpng.com/png/detail/847-8474751_download-empty-profile.png' width='30'/>
                 
                <img src='https://upload.wikimedia.org/wikipedia/commons/thumb/f/fe/Sort_up_font_awesome.svg/768px-Sort_up_font_awesome.svg.png'
                width='24' />{{ $post->votes }}
                <div style="font-size: 14px">{{ count($post->comments) }} comments</div>
            </div>
            <div style="margin-left: 8px">
                <a class="nav-link" href="{{ URL::to('post/1') }}">
                    <p style="font-size: 24px; font-weight: 900; margin-bottom: -24px">{{ $post->title }}</p>
                </a>
                <div style="display: flex">
                    <div>{{ $post->author->username }}</div>
                    <div style="margin-left: 8px; margin-right: 8px">·</div>
                    <div>Tag: <a href="/tag/{{ $post->tags->tag_id }}">{{ $post->tags->name }}</a></div>
                    <div style="margin-left: 8px; margin-right: 8px">·</div>
                    <div>{{ $post->date }}</div>
    
                </div>
            </div>
        </div>
    </div>
    @endforeach

    {{-- {{ json_encode($posts) }}  --}}
</div>