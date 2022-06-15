<?php

namespace App\Models;

// use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Notifications\Notifiable;
use Illuminate\Foundation\Auth\User as Authenticatable;
// use Illuminate\Database\Eloquent\Model;

// class AuthenticatedUser extends Model
class User extends Authenticatable
{
    // use HasFactory;
    use Notifiable;

    protected $table = 'authenticated_users';
    protected $primaryKey = 'user_id';
    public $timestamps = false;

    /**
     * The attributes that are mass assignable.
     *
     * @var array
     */
    protected $fillable = [
        'username', 'email', 'password',
    ];

    /**
     * The attributes that should be hidden for arrays.
     *
     * @var array
     */
    protected $hidden = [
        'password', 
    ];

    // associations one to one
    public function reported_post(){return $this->hasOne('App\Models\ReportPost');}

    public function liked_post(){return $this->hasOne('App\Models\LikedPost');}

    public function reported_comment(){return $this->hasOne('App\Models\ReportComment');}

    //associations one to many
    public function notifications(){return $this->hasMany('App\Models\Notification');}

    public function posts(){return $this->hasMany('App\Models\Post', 'author_id', 'user_id');}

    public function comments(){return $this->hasMany('App\Models\Comment');}

    //associations many to many
    public function followers() {return $this->hasMany('App\Models\Following', 'authenticated_user_id2');}
    public function following(){return $this->hasMany('App\Models\Following', 'authenticated_user_id1');}
}
