<div>
    @foreach ($comments as $item)
        <div style="margin-top: 20px">
            <div><a href="/post/{{ $item->post_id }}">{{ $item->date }} </a>
                <a href="/post/{{ $item->post_id }}">replied</a> 
                to a <a href="/post/{{ $item->post_id }}">post</a>
            </div>
            <div style="margin-top: 5px; padding: 10px; background-color: #ffbdbd">{{ $item->description }}</div>
        </div>
    @endforeach

    {{-- {{ json_encode($comments) }}  --}}
</div>