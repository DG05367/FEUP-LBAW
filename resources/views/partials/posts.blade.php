<div style="margin: 50px">
    <div style="border: 1px solid black; margin-bottom: 10px">
        <div style="display: flex; justify-content: space-between;
            align-items: center; height: 60px; border-bottom: 1px dashed black">
            <div style="display: flex; font-size: 22px">
                <div style="margin-left: 10px">Popular</div>
                <div style="margin-left: 10px">Latest</div>
                <div style="margin-left: 10px">Following</div>
            </div>
            <button style="margin-top: 10px; font-size: 18px; margin-right: 10px">NEW POST</button>
        </div>
        <div style="display: flex; height: 60px; align-items: center; font-size: 15px">
            <div style="margin-left: 10px">TODAY</div>
            <div style="margin-left: 10px">WEEKLY</div>
            <div style="margin-left: 10px">MONTHLY</div>
            <div style="margin-left: 10px">ALL-TIME</div>
        </div>
    </div>
    

    @foreach($posts as $post)
    <div style="border: 1px solid black; margin-bottom: 10px" id={{ $post->post_id }}>
        <div style="display: flex; margin: 12px">
            <div style="display: flex; flex-direction: column; align-items: center;
                        justify-content: space-around">
                <div style="display: flex; align-items: center">
                    <a href="/profile/{{ $post->author->user_id }}">
                        <img src='https://www.seekpng.com/png/detail/847-8474751_download-empty-profile.png' width='40'/>
                    </a>
                    <img src='https://upload.wikimedia.org/wikipedia/commons/thumb/f/fe/Sort_up_font_awesome.svg/768px-Sort_up_font_awesome.svg.png'
                    width='24' style="margin-left: 8px"/>{{ $post->votes }}
                    
                </div>
                <div style="font-size: 14px">{{ count($post->comments) }} comments</div>
            </div>
            <div style="margin-left: 20px; padding-left: 20px; border-left: 2px solid black">
                <a class="nav-link" href="{{ URL::to('post/1') }}">
                    <p style="font-size: 24px; font-weight: 900; margin-bottom: -24px">{{ $post->title }}</p>
                </a>
                <div style="display: flex">
                    <a href="/profile/{{ $post->author->user_id }}">{{ $post->author->username }}</a>
                    <div style="margin-left: 8px; margin-right: 8px">·</div>
                    <div>Tag: <a href="/tag/{{ $post->tags->tag_id }}">{{ $post->tags->name }}</a></div>
                    <div style="margin-left: 8px; margin-right: 8px">·</div>
                    <div>{{ $post->date }}</div>
    
                </div>
            </div>
        </div>
    </div>
    @endforeach

    <span>
        {{ $posts->links() }}
    </span>

    <style>
        .w-5 {
            display: none;
        }
    </style>
</div>