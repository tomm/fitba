# This is an autogenerated file for dynamic methods in UserFcmToken
# Please rerun bundle exec rake rails_rbi:models[UserFcmToken] to regenerate.

# typed: strong
module UserFcmToken::ActiveRelation_WhereNot
  sig { params(opts: T.untyped, rest: T.untyped).returns(T.self_type) }
  def not(opts, *rest); end
end

module UserFcmToken::GeneratedAttributeMethods
  sig { returns(ActiveSupport::TimeWithZone) }
  def created_at; end

  sig { params(value: T.any(Date, Time, ActiveSupport::TimeWithZone)).void }
  def created_at=(value); end

  sig { returns(T::Boolean) }
  def created_at?; end

  sig { returns(Integer) }
  def id; end

  sig { params(value: T.any(Numeric, ActiveSupport::Duration)).void }
  def id=(value); end

  sig { returns(T::Boolean) }
  def id?; end

  sig { returns(String) }
  def token; end

  sig { params(value: T.any(String, Symbol)).void }
  def token=(value); end

  sig { returns(T::Boolean) }
  def token?; end

  sig { returns(ActiveSupport::TimeWithZone) }
  def updated_at; end

  sig { params(value: T.any(Date, Time, ActiveSupport::TimeWithZone)).void }
  def updated_at=(value); end

  sig { returns(T::Boolean) }
  def updated_at?; end

  sig { returns(Integer) }
  def user_id; end

  sig { params(value: T.any(Numeric, ActiveSupport::Duration)).void }
  def user_id=(value); end

  sig { returns(T::Boolean) }
  def user_id?; end
end

module UserFcmToken::GeneratedAssociationMethods
  sig { returns(::User) }
  def user; end

  sig { params(args: T.untyped, block: T.nilable(T.proc.params(object: ::User).void)).returns(::User) }
  def build_user(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.params(object: ::User).void)).returns(::User) }
  def create_user(*args, &block); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.params(object: ::User).void)).returns(::User) }
  def create_user!(*args, &block); end

  sig { params(value: ::User).void }
  def user=(value); end
end

module UserFcmToken::CustomFinderMethods
  sig { params(limit: Integer).returns(T::Array[UserFcmToken]) }
  def first_n(limit); end

  sig { params(limit: Integer).returns(T::Array[UserFcmToken]) }
  def last_n(limit); end

  sig { params(args: T::Array[T.any(Integer, String)]).returns(T::Array[UserFcmToken]) }
  def find_n(*args); end

  sig { params(id: Integer).returns(T.nilable(UserFcmToken)) }
  def find_by_id(id); end

  sig { params(id: Integer).returns(UserFcmToken) }
  def find_by_id!(id); end
end

class UserFcmToken < ApplicationRecord
  include UserFcmToken::GeneratedAttributeMethods
  include UserFcmToken::GeneratedAssociationMethods
  extend UserFcmToken::CustomFinderMethods
  extend UserFcmToken::QueryMethodsReturningRelation
  RelationType = T.type_alias { T.any(UserFcmToken::ActiveRecord_Relation, UserFcmToken::ActiveRecord_Associations_CollectionProxy, UserFcmToken::ActiveRecord_AssociationRelation) }

  sig { params(args: T.untyped).returns(UserFcmToken::ActiveRecord_Relation) }
  def self.for_team_id(*args); end
end

class UserFcmToken::ActiveRecord_Relation < ActiveRecord::Relation
  include UserFcmToken::ActiveRelation_WhereNot
  include UserFcmToken::CustomFinderMethods
  include UserFcmToken::QueryMethodsReturningRelation
  Elem = type_member(fixed: UserFcmToken)

  sig { params(args: T.untyped).returns(UserFcmToken::ActiveRecord_Relation) }
  def for_team_id(*args); end
end

class UserFcmToken::ActiveRecord_AssociationRelation < ActiveRecord::AssociationRelation
  include UserFcmToken::ActiveRelation_WhereNot
  include UserFcmToken::CustomFinderMethods
  include UserFcmToken::QueryMethodsReturningAssociationRelation
  Elem = type_member(fixed: UserFcmToken)

  sig { params(args: T.untyped).returns(UserFcmToken::ActiveRecord_AssociationRelation) }
  def for_team_id(*args); end
end

class UserFcmToken::ActiveRecord_Associations_CollectionProxy < ActiveRecord::Associations::CollectionProxy
  include UserFcmToken::CustomFinderMethods
  include UserFcmToken::QueryMethodsReturningAssociationRelation
  Elem = type_member(fixed: UserFcmToken)

  sig { params(args: T.untyped).returns(UserFcmToken::ActiveRecord_AssociationRelation) }
  def for_team_id(*args); end

  sig { params(records: T.any(UserFcmToken, T::Array[UserFcmToken])).returns(T.self_type) }
  def <<(*records); end

  sig { params(records: T.any(UserFcmToken, T::Array[UserFcmToken])).returns(T.self_type) }
  def append(*records); end

  sig { params(records: T.any(UserFcmToken, T::Array[UserFcmToken])).returns(T.self_type) }
  def push(*records); end

  sig { params(records: T.any(UserFcmToken, T::Array[UserFcmToken])).returns(T.self_type) }
  def concat(*records); end
end

module UserFcmToken::QueryMethodsReturningRelation
  sig { returns(UserFcmToken::ActiveRecord_Relation) }
  def all; end

  sig { params(block: T.nilable(T.proc.void)).returns(UserFcmToken::ActiveRecord_Relation) }
  def unscoped(&block); end

  sig { params(args: T.untyped).returns(UserFcmToken::ActiveRecord_Relation) }
  def select(*args); end

  sig { params(args: T.untyped).returns(UserFcmToken::ActiveRecord_Relation) }
  def order(*args); end

  sig { params(args: T.untyped).returns(UserFcmToken::ActiveRecord_Relation) }
  def reorder(*args); end

  sig { params(args: T.untyped).returns(UserFcmToken::ActiveRecord_Relation) }
  def group(*args); end

  sig { params(args: T.untyped).returns(UserFcmToken::ActiveRecord_Relation) }
  def limit(*args); end

  sig { params(args: T.untyped).returns(UserFcmToken::ActiveRecord_Relation) }
  def offset(*args); end

  sig { params(args: T.untyped).returns(UserFcmToken::ActiveRecord_Relation) }
  def joins(*args); end

  sig { params(args: T.untyped).returns(UserFcmToken::ActiveRecord_Relation) }
  def left_joins(*args); end

  sig { params(args: T.untyped).returns(UserFcmToken::ActiveRecord_Relation) }
  def left_outer_joins(*args); end

  sig { params(args: T.untyped).returns(UserFcmToken::ActiveRecord_Relation) }
  def where(*args); end

  sig { params(args: T.untyped).returns(UserFcmToken::ActiveRecord_Relation) }
  def rewhere(*args); end

  sig { params(args: T.untyped).returns(UserFcmToken::ActiveRecord_Relation) }
  def preload(*args); end

  sig { params(args: T.untyped).returns(UserFcmToken::ActiveRecord_Relation) }
  def eager_load(*args); end

  sig { params(args: T.untyped).returns(UserFcmToken::ActiveRecord_Relation) }
  def includes(*args); end

  sig { params(args: T.untyped).returns(UserFcmToken::ActiveRecord_Relation) }
  def from(*args); end

  sig { params(args: T.untyped).returns(UserFcmToken::ActiveRecord_Relation) }
  def lock(*args); end

  sig { params(args: T.untyped).returns(UserFcmToken::ActiveRecord_Relation) }
  def readonly(*args); end

  sig { params(args: T.untyped).returns(UserFcmToken::ActiveRecord_Relation) }
  def or(*args); end

  sig { params(args: T.untyped).returns(UserFcmToken::ActiveRecord_Relation) }
  def having(*args); end

  sig { params(args: T.untyped).returns(UserFcmToken::ActiveRecord_Relation) }
  def create_with(*args); end

  sig { params(args: T.untyped).returns(UserFcmToken::ActiveRecord_Relation) }
  def distinct(*args); end

  sig { params(args: T.untyped).returns(UserFcmToken::ActiveRecord_Relation) }
  def references(*args); end

  sig { params(args: T.untyped).returns(UserFcmToken::ActiveRecord_Relation) }
  def none(*args); end

  sig { params(args: T.untyped).returns(UserFcmToken::ActiveRecord_Relation) }
  def unscope(*args); end

  sig { params(args: T.untyped).returns(UserFcmToken::ActiveRecord_Relation) }
  def merge(*args); end

  sig { params(args: T.untyped).returns(UserFcmToken::ActiveRecord_Relation) }
  def except(*args); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.void)).returns(UserFcmToken::ActiveRecord_Relation) }
  def extending(*args, &block); end

  sig do
    params(
      of: T.nilable(Integer),
      start: T.nilable(Integer),
      finish: T.nilable(Integer),
      load: T.nilable(T::Boolean),
      error_on_ignore: T.nilable(T::Boolean),
      block: T.nilable(T.proc.params(e: UserFcmToken::ActiveRecord_Relation).void)
    ).returns(ActiveRecord::Batches::BatchEnumerator)
  end
  def in_batches(of: 1000, start: nil, finish: nil, load: false, error_on_ignore: nil, &block); end
end

module UserFcmToken::QueryMethodsReturningAssociationRelation
  sig { returns(UserFcmToken::ActiveRecord_AssociationRelation) }
  def all; end

  sig { params(block: T.nilable(T.proc.void)).returns(UserFcmToken::ActiveRecord_Relation) }
  def unscoped(&block); end

  sig { params(args: T.untyped).returns(UserFcmToken::ActiveRecord_AssociationRelation) }
  def select(*args); end

  sig { params(args: T.untyped).returns(UserFcmToken::ActiveRecord_AssociationRelation) }
  def order(*args); end

  sig { params(args: T.untyped).returns(UserFcmToken::ActiveRecord_AssociationRelation) }
  def reorder(*args); end

  sig { params(args: T.untyped).returns(UserFcmToken::ActiveRecord_AssociationRelation) }
  def group(*args); end

  sig { params(args: T.untyped).returns(UserFcmToken::ActiveRecord_AssociationRelation) }
  def limit(*args); end

  sig { params(args: T.untyped).returns(UserFcmToken::ActiveRecord_AssociationRelation) }
  def offset(*args); end

  sig { params(args: T.untyped).returns(UserFcmToken::ActiveRecord_AssociationRelation) }
  def joins(*args); end

  sig { params(args: T.untyped).returns(UserFcmToken::ActiveRecord_AssociationRelation) }
  def left_joins(*args); end

  sig { params(args: T.untyped).returns(UserFcmToken::ActiveRecord_AssociationRelation) }
  def left_outer_joins(*args); end

  sig { params(args: T.untyped).returns(UserFcmToken::ActiveRecord_AssociationRelation) }
  def where(*args); end

  sig { params(args: T.untyped).returns(UserFcmToken::ActiveRecord_AssociationRelation) }
  def rewhere(*args); end

  sig { params(args: T.untyped).returns(UserFcmToken::ActiveRecord_AssociationRelation) }
  def preload(*args); end

  sig { params(args: T.untyped).returns(UserFcmToken::ActiveRecord_AssociationRelation) }
  def eager_load(*args); end

  sig { params(args: T.untyped).returns(UserFcmToken::ActiveRecord_AssociationRelation) }
  def includes(*args); end

  sig { params(args: T.untyped).returns(UserFcmToken::ActiveRecord_AssociationRelation) }
  def from(*args); end

  sig { params(args: T.untyped).returns(UserFcmToken::ActiveRecord_AssociationRelation) }
  def lock(*args); end

  sig { params(args: T.untyped).returns(UserFcmToken::ActiveRecord_AssociationRelation) }
  def readonly(*args); end

  sig { params(args: T.untyped).returns(UserFcmToken::ActiveRecord_AssociationRelation) }
  def or(*args); end

  sig { params(args: T.untyped).returns(UserFcmToken::ActiveRecord_AssociationRelation) }
  def having(*args); end

  sig { params(args: T.untyped).returns(UserFcmToken::ActiveRecord_AssociationRelation) }
  def create_with(*args); end

  sig { params(args: T.untyped).returns(UserFcmToken::ActiveRecord_AssociationRelation) }
  def distinct(*args); end

  sig { params(args: T.untyped).returns(UserFcmToken::ActiveRecord_AssociationRelation) }
  def references(*args); end

  sig { params(args: T.untyped).returns(UserFcmToken::ActiveRecord_AssociationRelation) }
  def none(*args); end

  sig { params(args: T.untyped).returns(UserFcmToken::ActiveRecord_AssociationRelation) }
  def unscope(*args); end

  sig { params(args: T.untyped).returns(UserFcmToken::ActiveRecord_AssociationRelation) }
  def merge(*args); end

  sig { params(args: T.untyped).returns(UserFcmToken::ActiveRecord_AssociationRelation) }
  def except(*args); end

  sig { params(args: T.untyped, block: T.nilable(T.proc.void)).returns(UserFcmToken::ActiveRecord_AssociationRelation) }
  def extending(*args, &block); end

  sig do
    params(
      of: T.nilable(Integer),
      start: T.nilable(Integer),
      finish: T.nilable(Integer),
      load: T.nilable(T::Boolean),
      error_on_ignore: T.nilable(T::Boolean),
      block: T.nilable(T.proc.params(e: UserFcmToken::ActiveRecord_AssociationRelation).void)
    ).returns(ActiveRecord::Batches::BatchEnumerator)
  end
  def in_batches(of: 1000, start: nil, finish: nil, load: false, error_on_ignore: nil, &block); end
end