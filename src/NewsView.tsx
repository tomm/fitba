import React from 'react';
import * as model from './model';
import { format } from 'date-fns';
import * as Uitk from './Uitk';

export function NewsView() {
  const [ news, setNews ] = React.useState<model.News[] | undefined>(undefined);

  React.useEffect(() => {
    model.getNews.call({}).then(setNews);
  }, []);

  if (news == undefined) {
    return <Uitk.Loading />
  } else {
    return <>
      <h2>Fitba News</h2>
      {
        news.length == 0
        ? <div className="center">
            The papers have nothing to say
          </div>
        : news.map(item =>
            <div className="inbox-message">
              <div className="news-article-title">{ item.title }</div>
              <div className="news-article-date">{ format(item.date, 'E d MMM HH:mm') }</div>
              <div className="news-article-body">{ item.body }</div>
            </div>
          )
      }
    </>
  }
}
