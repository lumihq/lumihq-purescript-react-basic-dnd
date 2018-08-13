module Basic where

import Prelude

import Data.Array ((!!), drop, mapWithIndex, take)
import Data.Foldable (for_)
import Data.Maybe (Maybe(Nothing), fromMaybe, maybe)
import React.Basic as React
import React.Basic.DOM as R
import React.Basic.DOM.Events (targetChecked)
import React.Basic.Events as Events
import React.Basic.ReactDND (DragDrop, DragDropContextProps, DragDropItemType(..), createDragDrop, createDragDropContext)
import React.Basic.ReactDND.Backends.HTML5Backend (html5Backend)

dndContext :: React.Component DragDropContextProps
dndContext = createDragDropContext html5Backend

dnd :: DragDrop { itemId :: String, index :: Int }
dnd = createDragDrop (DragDropItemType "TODO_ITEM")

component :: React.Component {}
component = React.component { displayName: "BasicExample", initialState, receiveProps, render }
  where
    initialState =
      { todos:
          [ { id: "a", text: "PureScript", done: true }
          , { id: "b", text: "React-Basic", done: true }
          , { id: "c", text: "React-DND-Basic", done: false }
          ]
      }

    receiveProps _ =
      pure unit

    render { state, setState } =
      React.element dndContext
        { child:
            React.fragment
              [ R.h1_ [ R.text "Todos" ]
              , R.p_ [ R.text "Drag to reorder the list:" ]
              , R.section_ (mapWithIndex renderTodo state.todos)
              ]
        }

      where
        renderTodo index todo =
          React.element dnd.dragSource
            { beginDrag: \_ -> pure
                { itemId: todo.id
                , index
                }
            , endDrag: const (pure unit)
            , canDrag: const (pure true)
            , isDragging: \{ item: draggingItem } ->
                pure $ maybe false (\i -> i.itemId == todo.id) draggingItem
            , render: \{ connectDragSource, isDragging } ->
                React.element dnd.dropTarget
                  { drop: \{ item: dragItem } -> do
                      for_ (_.index <$> dragItem) \dragItemIndex ->
                        setState \s -> s
                          { todos = moveItem dragItemIndex index s.todos
                          }
                      pure Nothing
                  , hover: const (pure unit)
                  , canDrop: const (pure true)
                  , render: \{ connectDropTarget, isOver, item: maybeDragItem } ->
                      connectDragSource $ connectDropTarget $
                        R.div
                          { style: R.css
                              { padding: "0.3rem 0.8rem"
                              , alignItems: "center"
                              , borderTop:
                                  if isOver && (fromMaybe false ((\dragItem -> dragItem.index > index) <$> maybeDragItem))
                                  then "0.2rem solid #0044e4"
                                  else "0.2rem solid transparent"
                              , borderBottom:
                                  if isOver && (fromMaybe false ((\dragItem -> dragItem.index < index) <$> maybeDragItem))
                                  then "0.2rem solid #0044e4"
                                  else "0.2rem solid transparent"
                              , opacity: if isDragging then 0.1 else 1.0
                              }
                          , children:
                              [ R.input
                                  { "type": "checkbox"
                                  , checked: todo.done
                                  , onChange: Events.handler targetChecked \checked -> do
                                      setState \s -> s
                                        { todos = s.todos <#> \t ->
                                            if t.id == todo.id
                                            then t { done = fromMaybe false checked }
                                            else t
                                        }
                                  }
                              , R.text todo.text
                              ]
                          }
                  }
            }

moveItem :: forall a. Int -> Int -> Array a -> Array a
moveItem fromIndex toIndex items =
  let
    item = items !! fromIndex
    items' = take fromIndex items <> drop (fromIndex + 1) items
  in
    take toIndex items'
      <> maybe [] pure item
      <> drop toIndex items'
