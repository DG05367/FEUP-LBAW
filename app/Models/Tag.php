<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Tag extends Model
{
    use HasFactory;

    protected $primaryKey = 'tag_id';
    protected $table = 'tag';
    public $timestamps = false;

    public function moderators(){return $this->hasMany('App\Models\Moderator');}

    public function post(){return $this->hasMany('App\Models\Post');}
}
