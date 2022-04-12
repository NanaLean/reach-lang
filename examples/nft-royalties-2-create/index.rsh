'reach 0.1';
'use strict';

export const main = Reach.App(() => {
  const Creator = Participant('Creator', {
    getId: Fun([], UInt),
  });
  const Owner   = Participant('Owner', {
    newOwner: Fun([], Address),
  });
  init();

  Creator.only(() => {
    const id = declassify(interact.getId()); 
  });
  Creator.publish(id);
  commit();

  Owner.only(() => {
    const newOwner = declassify(interact.newOwner());
  });
  Owner.publish(newOwner);
  commit();
});